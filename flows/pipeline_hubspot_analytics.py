"""pipeline_hubspot_analytics — orquestração (Prefect) do ciclo de watermark.

Camada fina: só sequência, retries e logging. A regra de negócio vive em
services/, o contrato em domain/, a fronteira AWS em core/ e o cursor em
persistence/ — mesmo desenho do hubspot-api-service.

Ciclo: watermark -> extração (Lambda) -> associações -> raw JSONL ->
dbt build -> avanço do watermark (somente após o dbt concluir; falhou, a
próxima execução repete a janela — carga idempotente no dbt).
"""

from __future__ import annotations

import duckdb
from prefect import flow, task, get_run_logger

from constants.config import DUCKDB_PATH, OBJETOS
from core.lambda_client import HubspotLambdaClient
from domain.schemas import BlocoAssociacoes, BlocoExtraido
from persistence.watermarks import WatermarkStore
from services.associations import AssociationsService
from services.extraction import ExtractionService
from services.raw_writer import gravar_raw, gravar_raw_associacoes
from services.mysql_publisher import publicar_gold
from services.dbt_runner import rodar_dbt


@task(retries=2, retry_delay_seconds=30)
def task_extrair(object_type: str, watermark: str | None) -> BlocoExtraido:
    return ExtractionService(HubspotLambdaClient()).extrair(object_type, watermark)


@task(retries=2, retry_delay_seconds=30)
def task_resolver_associacoes(bloco: BlocoExtraido) -> list[BlocoAssociacoes]:
    return AssociationsService(HubspotLambdaClient()).resolver(bloco)


@task
def task_gravar_raw(bloco: BlocoExtraido):
    return gravar_raw(bloco)


@task
def task_gravar_raw_associacoes(blocos: list[BlocoAssociacoes]):
    return [gravar_raw_associacoes(b) for b in blocos]


@task
def task_rodar_dbt() -> None:
    rodar_dbt()

@task(retries=1, retry_delay_seconds=60)
def task_publicar_mysql() -> None:
    publicar_gold()


@flow(name="pipeline_hubspot_analytics")
def pipeline_hubspot_analytics(objetos: list[str] | None = None) -> None:
    log = get_run_logger()
    objetos = objetos or OBJETOS

    con = duckdb.connect(DUCKDB_PATH)
    store = WatermarkStore(con)

    blocos: list[BlocoExtraido] = []
    for obj in objetos:
        wm = store.get(obj)
        log.info("[%s] watermark atual: %s", obj, wm or "(nenhum — carga full)")
        bloco = task_extrair(obj, wm)
        task_gravar_raw(bloco)
        task_gravar_raw_associacoes(task_resolver_associacoes(bloco))
        blocos.append(bloco)
    
    if any(not b.vazio for b in blocos):
        task_rodar_dbt()
        task_publicar_mysql()
    else:
        log.info("Nenhum registro novo em nenhum objeto — dbt não executado")
    
    for bloco in blocos:
        if bloco.novo_watermark:
            store.set(bloco.object_type, bloco.novo_watermark)
            log.info(
                "[%s] watermark avançado para %s (%d registros, %d invocações)",
                bloco.object_type, bloco.novo_watermark,
                len(bloco.records), bloco.invocacoes,
            )
 
    con.close()


if __name__ == "__main__":
    pipeline_hubspot_analytics()
