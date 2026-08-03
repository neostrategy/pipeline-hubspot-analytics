"""Resolução de associações para os IDs que vieram na janela incremental.

A Search API do HubSpot não devolve `associations` — só o `extract` full
devolve. Este serviço chama a action `associations` do Lambda com os IDs
alterados, para que os vínculos (contato / negócio / empresa) cheguem ao
banco também na carga incremental.
"""

from __future__ import annotations

import logging

from constants.config import ASSOC_IDS_POR_INVOCACAO, ASSOCIACOES
from core.lambda_client import HubspotLambdaClient
from domain.schemas import BlocoAssociacoes, BlocoExtraido

log = logging.getLogger(__name__)


class AssociationsService:
    def __init__(self, client: HubspotLambdaClient):
        self.client = client

    def resolver(self, bloco: BlocoExtraido) -> list[BlocoAssociacoes]:
        """Resolve todas as associações configuradas para um bloco extraído."""
        alvos = ASSOCIACOES.get(bloco.object_type, [])
        if not alvos or bloco.vazio:
            return []

        ids = bloco.ids
        resultados: list[BlocoAssociacoes] = []

        for to_object in alvos:
            resultado = BlocoAssociacoes(
                from_object=bloco.object_type, to_object=to_object,
            )
            for start in range(0, len(ids), ASSOC_IDS_POR_INVOCACAO):
                chunk = ids[start:start + ASSOC_IDS_POR_INVOCACAO]
                resultado.invocacoes += 1
                pagina = self.client.invocar({
                    "action": "associations",
                    "from_object": bloco.object_type,
                    "to_object": to_object,
                    "ids": chunk,
                })
                resultado.pairs.extend(pagina.get("pairs", []))

            log.info(
                "[assoc] %s -> %s: %d pares (%d ids, %d invocações)",
                bloco.object_type, to_object, len(resultado.pairs),
                len(ids), resultado.invocacoes,
            )
            resultados.append(resultado)

        return resultados
