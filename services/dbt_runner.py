"""Execução do dbt build (staging e marts em Iceberg, via Athena)."""

from __future__ import annotations

import logging
import subprocess

from constants.config import DBT_PROJECT_DIR, DBT_SELECT, DBT_TARGET

log = logging.getLogger(__name__)


def rodar_dbt(select: str = DBT_SELECT) -> None:
    resultado = subprocess.run(
        ["dbt", "build", "--select", select,
         "--target", DBT_TARGET,
         "--project-dir", DBT_PROJECT_DIR, "--profiles-dir", DBT_PROJECT_DIR],
        capture_output=True, text=True,
    )
    log.info(resultado.stdout)
    if resultado.returncode != 0:
        log.error("dbt stdout:\n%s", resultado.stdout)
        log.error("dbt stderr:\n%s", resultado.stderr)
        raise RuntimeError("dbt build falhou — watermarks não serão avançados")