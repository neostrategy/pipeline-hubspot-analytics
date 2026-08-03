"""Execução do dbt build (staging/silver/gold no DuckDB)."""

from __future__ import annotations

import logging
import os
import subprocess

from constants.config import DBT_PROJECT_DIR, DBT_SELECT, DUCKDB_PATH

log = logging.getLogger(__name__)


def rodar_dbt(select: str = DBT_SELECT) -> None:
    resultado = subprocess.run(
        ["dbt", "build", "--select", select,
         "--project-dir", DBT_PROJECT_DIR, "--profiles-dir", DBT_PROJECT_DIR],
        capture_output=True, text=True,
        env={**os.environ, "DUCKDB_PATH": DUCKDB_PATH},
    )
    log.info(resultado.stdout)
    if resultado.returncode != 0:
        log.error(resultado.stderr)
        raise RuntimeError("dbt build falhou — watermarks não serão avançados")
