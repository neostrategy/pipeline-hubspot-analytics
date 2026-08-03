"""Regra de extração incremental: cursor, fatiamento de janela e watermark.

Não conhece Prefect nem AWS diretamente — recebe um HubspotLambdaClient e
devolve um BlocoExtraido. Toda a lógica é testável com um client fake.
"""

from __future__ import annotations

import logging

from constants.config import (
    LASTMOD,
    LASTMOD_DEFAULT,
    MAX_INVOCACOES,
    SEARCH_CURSOR_SAFETY,
)
from core.lambda_client import HubspotLambdaClient
from domain.schemas import BlocoExtraido

log = logging.getLogger(__name__)


class ExtractionService:
    def __init__(self, client: HubspotLambdaClient):
        self.client = client

    def extrair(self, object_type: str, watermark: str | None) -> BlocoExtraido:
        """Extrai tudo que mudou desde o watermark.

        Sem watermark -> `extract` (carga histórica full).
        Com watermark -> `search` incremental; quando o cursor se aproxima
        do teto de 10.000 da Search API, reabre a busca com `since` =
        maior lastmodified já visto (janela fatiada) — correto porque a
        busca é ordenada ascendente. GTE reprocessa o registro de borda,
        e o upsert incremental no dbt absorve a repetição.
        """
        lastmod_prop = LASTMOD.get(object_type, LASTMOD_DEFAULT)
        action = "search" if watermark else "extract"

        bloco = BlocoExtraido(object_type=object_type)
        since = watermark
        after: str | None = None

        while bloco.invocacoes < MAX_INVOCACOES:
            bloco.invocacoes += 1
            payload: dict = {"action": action, "object_type": object_type}
            if action == "search":
                payload["since"] = since
            if after:
                payload["after"] = after

            pagina = self.client.invocar(payload)
            registros = pagina.get("records", [])
            bloco.records.extend(registros)

            for r in registros:
                v = r.get(lastmod_prop)
                if v and (bloco.novo_watermark is None or v > bloco.novo_watermark):
                    bloco.novo_watermark = v

            after = pagina.get("next_after")
            log.info(
                "[%s] invocação %d: +%d registros (acum=%d, next_after=%s)",
                object_type, bloco.invocacoes, len(registros),
                len(bloco.records), after,
            )

            if not after:
                return bloco

            if (action == "search" and after.isdigit()
                    and int(after) >= SEARCH_CURSOR_SAFETY):
                if not bloco.novo_watermark:
                    raise RuntimeError(
                        f"[{object_type}] cursor no teto sem lastmodified "
                        "para fatiar a janela"
                    )
                log.warning(
                    "[%s] cursor em %s — fatiando janela: novo since=%s",
                    object_type, after, bloco.novo_watermark,
                )
                since, after = bloco.novo_watermark, None

        raise RuntimeError(
            f"[{object_type}] atingiu MAX_INVOCACOES={MAX_INVOCACOES}; "
            "backlog anormal — investigar antes de reexecutar"
        )
