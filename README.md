# pipeline-hubspot-analytics

Pipeline incremental HubSpot -> DuckLake (raw -> staging -> silver -> gold),
orquestrado com Prefect e consumindo o `hubspot-api-service` (Lambda).

O armazenamento analítico é um lakehouse **DuckLake**: os dados vivem em
Parquet e os metadados (schema, snapshots, quais arquivos compõem cada
tabela) num banco relacional. O DuckDB é apenas o motor que executa —
não guarda estado. Ver "Armazenamento (DuckLake)".

## Distribuição de responsabilidade

| Camada | Pasta | Responsabilidade | Depende de |
|---|---|---|---|
| Orquestração | `flows/` | Sequência, retries, logging (Prefect) | services, persistence |
| Regra de negócio | `services/` | Extração (cursor + fatiamento), raw JSONL, dbt | core, domain, constants |
| Fronteira externa | `core/` | Invocação do Lambda (boto3) | constants |
| Contratos | `domain/` | Dataclasses trocadas entre camadas | — |
| Estado | `persistence/` | Watermark por objeto (DuckDB; DynamoDB na nuvem) | — |
| Armazenamento | catálogo + `data_path` | Tabelas analíticas (DuckLake) | — |
| Configuração | `constants/` | Valores de ambiente e limites | — |

Regras da disciplina:
- `flows/` não contém regra de negócio; `services/` não conhece Prefect.
- Toda troca entre camadas usa os contratos de `domain/`.
- `core/` é a única camada que fala com a AWS.
- Watermark só avança após o `dbt build` concluir (execução idempotente).

## Executar

```bash
pip install -r requirements.txt
python -m flows.pipeline_hubspot_analytics
```

Configuração via `.env` na raiz (ver `.env.example`), carregado por
`python-dotenv` em `constants/config.py`:

| Variável | Default | Para que serve |
|---|---|---|
| `HUBSPOT_RAW_DIR` | `data/raw/hubspot` | Onde ficam os JSONL do raw |
| `DUCKLAKE_CATALOG` | `data/lake_catalog.ducklake` | Catálogo de metadados |
| `DUCKLAKE_DATA_PATH` | `data/lake_files/` | Onde o DuckLake grava Parquet |
| `DBT_TARGET` | `lake` | Target do `profiles.yml` |
| `DBT_PROJECT_DIR` | `dbt` | Diretório do projeto dbt |

Rodar o dbt na mão com o `.env` carregado (da raiz do repo):

```bash
dotenv run -- dbt build --target lake --project-dir dbt --profiles-dir dbt
```

Caminhos relativos resolvem a partir da **raiz do repo**, não de `dbt/` —
o `dbt_runner` invoca com `--project-dir` e herda o diretório do processo.

## Armazenamento (DuckLake)

Duas peças independentes, que podem migrar separadamente:

- **Catálogo** — banco relacional com os metadados. Hoje um arquivo
  DuckDB local; pode virar Postgres ou MySQL sem tocar em modelo nenhum,
  porque quem escreve nele é o DuckDB, não o dbt.
- **Data path** — onde os Parquet moram. Hoje `data/lake_files/`; vira
  `s3://.../lakehouse/` trocando só a configuração do lake.

O `DATA_PATH` fica gravado no catálogo na criação do lake e **não pode ser
alterado depois** — migrar de local exige copiar os arquivos e reescrever
o catálogo. Na prática: criar um lake novo e reconstruir.

Escritas são imutáveis. Um `DELETE` ou um `merge` incremental não
reescreve o Parquet original: cria um arquivo de deleção ao lado e o
catálogo registra a partir de qual snapshot cada arquivo vale. Daí o time
travel sair de graça:

```sql
ATTACH 'ducklake:data/lake_catalog.ducklake' AS lake_catalog;
SELECT snapshot_id, schema_version, changes FROM ducklake_snapshots('lake_catalog');
SELECT count(*) FROM main_gold.analytics_deals AT (VERSION => 40);
```

Cada `dbt build` gera vários snapshots — o histórico de transformação fica
auditável, o que o `analytics.duckdb` anterior não permitia.

### Decisões forçadas pelo par dbt-duckdb + DuckLake

Três ajustes não-óbvios. **Não reverter sem reler isto:**

1. **`path: "ducklake:..."` no lugar de `:memory:` + `attach`.** Com o
   lake anexado a uma conexão `:memory:`, a conexão tem dois bancos, e o
   DuckDB só permite escrever em um banco por transação. Snapshots e
   materializações `table` fazem duas escritas (relação temporária +
   destino) e quebravam com
   `a single transaction can only write to a single attached database`.
   Com o lake como banco padrão, não há segundo catálogo.

2. **`threads: 1`.** O rename da relação `__dbt_tmp` resolve contra o
   schema corrente da conexão; em paralelo, threads trocam esse contexto
   entre si e modelos falham de forma aleatória com
   `__dbt_tmp does not exist`. Um pipeline diário não perde nada com isso
   (~17s contra ~12s).

3. **Override de `duckdb__drop_relation`** em `dbt/macros/`. A
   materialização de snapshot do dbt derruba a relação temporária com
   `drop ... cascade`, e o DuckLake responde
   `Cascade Drop not supported`. O override remove o `cascade`. Seguro
   porque nada depende dessas relações temporárias.

### Manutenção (obrigatória em produção)

Cada build cria Parquet novo; ~13 arquivos por execução na configuração
atual. Sem manutenção isso chega a milhares no primeiro ano, e no S3 cada
arquivo é uma requisição HTTP.

```sql
CALL ducklake_merge_adjacent_files('lake_catalog');
CALL ducklake_expire_snapshots('lake_catalog',
     older_than => now() - INTERVAL '30 days', dry_run => true);
```

`merge_adjacent_files` funde arquivos pequenos e aplica deleções
pendentes, mas não apaga nada — os arquivos antigos seguem referenciados
pelos snapshots antigos. Só `expire_snapshots` libera espaço, e o custo
disso é perder time travel além da janela escolhida. **A janela é decisão
de negócio:** quanto tempo para trás é preciso auditar de fato.

Pendente: flow Prefect semanal chamando as duas rotinas.

## Modelo analítico

`analytics_contacts` é o hub. Dela derivam `mart_entradas` (quem entrou,
quando, origem), os negócios (com `analytics_deal_stage_hist`, SCD2 do
funil — nunca recriar) e `fct_activities`. Documentação do modelo em
DBML: `docs/hubspot_analytics.dbml` (colar em dbdiagram.io).

## Pendências conhecidas

- `dim_owners` e `dim_stages`: endpoints `/crm/v3/owners` e
  `/crm/v3/pipelines` no `hubspot-api-service` (aposentam o `ilike` que
  deriva `is_won`/`is_closed`).
- Eventos de e-mail: aguardando `email_events.py` no serviço — destrava
  `analytics_email_events` e `fct_touches` (atribuição multi-toque).
- `utm_*` são propriedades custom: confirmar no portal antes do deploy.
- Housekeeping dos JSONL do raw quando o volume crescer.
- Flow de manutenção do lake (merge + expire) ainda não existe.
- Raw ainda grava em disco local — `services/raw_writer.py` é a única
  camada a mudar quando for para o S3.
- `WatermarkStore` ainda usa arquivo DuckDB local. Com o lake como
  destino, essa tabela não cabe lá (o DuckLake não impõe primary key, e
  o upsert usa `ON CONFLICT`): o destino é DynamoDB.
- Migração do gold para MySQL: **descartada**. O consumo passa a sair do
  DuckLake; falta definir como o BI conecta (DuckDB read-only servindo,
  ou export de marts em Parquet).

## dbt (transformações)

Projeto em `dbt/`. Dois targets no `profiles.yml`: `lake` (DuckLake,
padrão) e `dev` (arquivo `analytics.duckdb`, mantido como rota de fuga).
O `dbt_project.yml` não sabe onde o dado mora — quem decide é o profile.

- `models/staging/` — 1 view por objeto: lê os JSONL do raw com
  `read_json_auto(..., union_by_name=true)` (arquivos de extract full e de
  search incremental têm colunas diferentes), deduplica por `id` ficando
  com o `load_ts` mais recente, tipa e renomeia.
- `snapshots/snap_deals_stage.sql` — SCD2 de `dealstage` (strategy=check).
- `macros/stg_associacoes.sql` — staging genérico dos pares de associação
  (8 combinações: deals/calls/meetings -> contacts/deals/companies).
- `models/gold/` — incrementais com `unique_key` (contacts, companies,
  deals, calls, meetings), `analytics_deal_stage_hist` do snapshot,
  tabelas `assoc_*`, `fct_activities` (calls + meetings atribuídos a
  contato/negócio/empresa) e `mart_entradas` (coorte de entradas).

Executar manualmente:

```bash
dotenv run -- dbt build --select tag:hubspot --target lake \
  --project-dir dbt --profiles-dir dbt
```

Ajustes pendentes de negócio: ids reais dos estágios de fechamento em
`analytics_deals.is_won/is_closed`; housekeeping dos JSONL do raw
(arquivar processados quando o volume crescer).