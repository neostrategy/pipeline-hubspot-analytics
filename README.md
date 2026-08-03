# pipeline-hubspot-analytics

Pipeline incremental HubSpot -> DuckDB (raw -> staging -> silver -> gold),
orquestrado com Prefect e consumindo o `hubspot-api-service` (Lambda).

## Distribuição de responsabilidade

| Camada | Pasta | Responsabilidade | Depende de |
|---|---|---|---|
| Orquestração | `flows/` | Sequência, retries, logging (Prefect) | services, persistence |
| Regra de negócio | `services/` | Extração (cursor + fatiamento), raw JSONL, dbt | core, domain, constants |
| Fronteira externa | `core/` | Invocação do Lambda (boto3) | constants |
| Contratos | `domain/` | Dataclasses trocadas entre camadas | — |
| Estado | `persistence/` | Watermark por objeto (DuckDB; DynamoDB na nuvem) | — |
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

Variáveis: `DUCKDB_PATH` (default `data/analytics.duckdb`),
`HUBSPOT_RAW_DIR` (default `data/raw/hubspot`). Na máquina com DLP,
exportar o CA raiz e definir `AWS_CA_BUNDLE`/`REQUESTS_CA_BUNDLE`.

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
- Migração do gold para MySQL (decisão adiada; DuckDB por enquanto).

## dbt (transformações)

Projeto em `dbt/` (profiles com `DUCKDB_PATH` via env, padrão do time).

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
dbt build --select tag:hubspot --project-dir dbt --profiles-dir dbt
```

Ajustes pendentes de negócio: ids reais dos estágios de fechamento em
`analytics_deals.is_won/is_closed`; housekeeping dos JSONL do raw
(arquivar processados quando o volume crescer).
