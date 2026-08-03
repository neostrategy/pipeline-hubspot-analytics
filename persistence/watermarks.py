"""Persistência do cursor incremental por objeto.

Implementação atual em DuckDB (pipeline rodando local). Ao migrar o flow
para a nuvem, trocar por uma implementação DynamoDB mantendo a mesma
interface (get / set) — o resto do pipeline não muda.
"""

from __future__ import annotations

import duckdb


class WatermarkStore:
    def __init__(self, con: duckdb.DuckDBPyConnection):
        self.con = con
        self.con.execute(
            """
            CREATE TABLE IF NOT EXISTS meta_watermarks (
                object_type  VARCHAR PRIMARY KEY,
                watermark    VARCHAR,          -- ISO 8601 UTC
                updated_at   TIMESTAMP
            )
            """
        )

    def get(self, object_type: str) -> str | None:
        row = self.con.execute(
            "SELECT watermark FROM meta_watermarks WHERE object_type = ?",
            [object_type],
        ).fetchone()
        return row[0] if row else None

    def set(self, object_type: str, watermark: str) -> None:
        self.con.execute(
            """
            INSERT INTO meta_watermarks VALUES (?, ?, now())
            ON CONFLICT (object_type) DO UPDATE
               SET watermark = excluded.watermark,
                   updated_at = excluded.updated_at
            """,
            [object_type, watermark],
        )
