"""Execução do dbt build (staging/silver/gold no DuckLake)."""

from __future__ import annotations

import logging
import os
import subprocess

from constants.config import (
    DBT_PROJECT_DIR,
    DBT_SELECT,
    DBT_TARGET,
    DUCKLAKE_CATALOG,
    DUCKLAKE_DATA_PATH,
)

log = logging.getLogger(__name__)


def rodar_dbt(select: str = DBT_SELECT) -> None:
    resultado = subprocess.run(
        ["dbt", "build", "--select", select,
         "--target", DBT_TARGET,
         "--project-dir", DBT_PROJECT_DIR, "--profiles-dir", DBT_PROJECT_DIR],
        capture_output=True, text=True,
        env={**os.environ,
             "DUCKLAKE_CATALOG": DUCKLAKE_CATALOG,
             "DUCKLAKE_DATA_PATH": DUCKLAKE_DATA_PATH},
    )
    log.info(resultado.stdout)
    if resultado.returncode != 0:
        log.error("dbt stdout:\n%s", resultado.stdout)
        log.error("dbt stderr:\n%s", resultado.stderr)
        raise RuntimeError("dbt build falhou — watermarks não serão avançados")
        