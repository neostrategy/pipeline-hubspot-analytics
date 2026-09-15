"""Publicação da camada gold do DuckLake no MySQL para consumo do BI.

O DuckLake é a fonte da verdade; o MySQL é uma cópia publicada. A carga é
full replace por tabela: recriar 40k linhas custa segundos e é idempotente
por construção — se um run morreu no meio, o próximo conserta sozinho, sem
precisar replicar a lógica de `unique_key` do dbt fora do dbt.

Troca atômica: os dados vão para `<tabela>__new` e só entram em produção
num `RENAME TABLE`, que o MySQL executa de forma atômica. O BI nunca vê
tabela vazia nem parcial.

Os tipos e índices vivem no DDL versionado (sql/mysql_gold_ddl.sql), não
são inferidos aqui — `CREATE TABLE ... LIKE` copia a definição da tabela
em produção, incluindo chaves e índices.
"""

from __future__ import annotations

import logging

import duckdb

from constants.config import (
    DUCKLAKE_CATALOG,
    GOLD_SCHEMA,
    GOLD_TABLES,
    MYSQL_DATABASE,
    MYSQL_HOST,
    MYSQL_PASSWORD,
    MYSQL_PORT,
    MYSQL_USER,
)

log = logging.getLogger(__name__)


def _conectar() -> duckdb.DuckDBPyConnection:
    """DuckDB em memória com o lake (leitura) e o MySQL (escrita) anexados."""
    con = duckdb.connect()
    con.execute("INSTALL ducklake; LOAD ducklake;")
    con.execute("INSTALL mysql; LOAD mysql;")

    con.execute(f"ATTACH 'ducklake:{DUCKLAKE_CATALOG}' AS lake (READ_ONLY)")

    dsn = (
        f"host={MYSQL_HOST} port={MYSQL_PORT} "
        f"user={MYSQL_USER} password={MYSQL_PASSWORD} "
        f"database={MYSQL_DATABASE}"
    )
    con.execute(f"ATTACH '{dsn}' AS bi (TYPE mysql)")
    return con


def _colunas_destino(con: duckdb.DuckDBPyConnection, tabela: str) -> list[str]:
    """Colunas da tabela em produção, na ordem definida pelo DDL.

    O mapeamento é por nome, não por posição: se um modelo do dbt ganhar
    coluna nova e o DDL não for atualizado, a coluna é ignorada; se o
    modelo perder uma coluna que o DDL espera, a carga falha alto no
    SELECT em vez de gravar lixo deslocado.
    """
    linhas = con.execute(
        """
        SELECT column_name
        FROM bi.information_schema.columns
        WHERE table_schema = ? AND table_name = ?
        ORDER BY ordinal_position
        """,
        [MYSQL_DATABASE, tabela],
    ).fetchall()

    if not linhas:
        raise RuntimeError(
            f"Tabela '{tabela}' não existe no MySQL. "
            "Rode sql/mysql_gold_ddl.sql antes da primeira publicação."
        )
    return [linha[0] for linha in linhas]


def _mysql(con: duckdb.DuckDBPyConnection, sql: str) -> None:
    """Executa DDL direto no MySQL (não passa pelo planner do DuckDB).

    O DuckDB cacheia o schema do banco anexado; como estas instruções
    correm por fora dele, o cache precisa ser invalidado, senão as
    tabelas criadas aqui ficam invisíveis para o INSERT seguinte.
    """
    con.execute("CALL mysql_execute('bi', ?)", [sql])
    con.execute("CALL mysql_clear_cache()")


def publicar_tabela(con: duckdb.DuckDBPyConnection, tabela: str) -> int:
    colunas = _colunas_destino(con, tabela)
    lista = ", ".join(f'"{c}"' for c in colunas)

    _mysql(con, f"DROP TABLE IF EXISTS `{tabela}__new`")
    _mysql(con, f"CREATE TABLE `{tabela}__new` LIKE `{tabela}`")

    con.execute(
        f'INSERT INTO bi."{tabela}__new" '
        f"SELECT {lista} FROM lake.{GOLD_SCHEMA}.{tabela}"
    )

    total = con.execute(f'SELECT count(*) FROM bi."{tabela}__new"').fetchone()[0]

    # RENAME múltiplo é atômico no MySQL: não existe instante em que a
    # tabela de produção esteja ausente.
    _mysql(con, f"DROP TABLE IF EXISTS `{tabela}__old`")
    _mysql(
        con,
        f"RENAME TABLE `{tabela}` TO `{tabela}__old`, "
        f"`{tabela}__new` TO `{tabela}`",
    )
    _mysql(con, f"DROP TABLE `{tabela}__old`")

    log.info("[mysql] %s publicada (%d linhas)", tabela, total)
    return total


def publicar_gold(tabelas: list[str] | None = None) -> dict[str, int]:
    """Publica as tabelas gold. Retorna {tabela: linhas}.

    Falha na primeira tabela com erro: publicar metade do gold é pior que
    não publicar nada, porque o BI passa a cruzar períodos diferentes sem
    perceber.
    """
    tabelas = tabelas or GOLD_TABLES
    con = _conectar()
    try:
        resultado = {t: publicar_tabela(con, t) for t in tabelas}
        log.info(
            "[mysql] publicação concluída: %d tabelas, %d linhas",
            len(resultado), sum(resultado.values()),
        )
        return resultado
    finally:
        con.close()