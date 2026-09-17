"""pipeline_hubspot_analytics — orquestração (Prefect) do ciclo de watermark.

Camada fina: só sequência, retries e logging. A regra de negócio vive em
services/, o contrato em domain/, a fronteira AWS em core/ e o cursor em
persistence/ — mesmo desenho do hubspot-api-service.

Ciclo: watermark -> extração (Lambda) -> associações -> raw JSONL no S3 ->
dbt build (Athena/Iceberg) -> avanço do watermark (somente após o dbt
concluir; falhou, a próxima execução repete a janela — carga idempotente).
"""

from __future__ import annotations

import os

from prefect import flow, get_run_logger, task

from constants.config import AWS_REGION, OBJETOS
from core.lambda_client import HubspotLambdaClient
from domain.schemas import BlocoAssociacoes, BlocoExtraido
from persistence.watermarks import WatermarkStore
from services.associations import AssociationsService
from services.dbt_runner import rodar_dbt
from services.extraction import ExtractionService
from services.raw_writer import gravar_raw, gravar_raw_associacoes

AWS_CREDENTIALS_BLOCK = os.environ.get("AWS_CREDENTIALS_BLOCK", "aws-neotass")


def _carregar_credenciais_aws() -> bool:
    """Exporta as credenciais do bloco do Prefect para o ambiente.

    Necessário no compute gerenciado do Prefect Cloud, que não tem instance
    profile nem perfil local. Exportar para o ambiente (em vez de usar a
    sessão do bloco) faz o dbt herdar as mesmas credenciais, já que ele roda
    como subprocesso.

    Quando o worker migrar para uma EC2 com instance profile, esta função
    deixa de ser necessária: basta remover o bloco e a cadeia padrão do
    boto3 resolve sozinha.
    """
    try:
        from prefect_aws import AwsCredentials
    except ImportError:
        return False

    try:
        creds = AwsCredentials.load(AWS_CREDENTIALS_BLOCK)
    except Exception:
        return False

    if not creds.aws_access_key_id:
        return False

    os.environ["AWS_ACCESS_KEY_ID"] = creds.aws_access_key_id
    os.environ["AWS_SECRET_ACCESS_KEY"] = (
        creds.aws_secret_access_key.get_secret_value()
    )
    os.environ["AWS_DEFAULT_REGION"] = creds.region_name or AWS_REGION
    return True


@task(retries=2, retry_delay_seconds=30)
def task_extrair(object_type: str, watermark: str | None) -> BlocoExtraido:
    return ExtractionService(HubspotLambdaClient()).extrair(object_type, watermark)


@task(retries=2, retry_delay_seconds=30)
def task_resolver_associacoes(bloco: BlocoExtraido) -> list[BlocoAssociacoes]:
    return AssociationsService(HubspotLambdaClient()).resolver(bloco)


@task(retries=2, retry_delay_seconds=15)
def task_gravar_raw(bloco: BlocoExtraido) -> str | None:
    return gravar_raw(bloco)


@task(retries=2, retry_delay_seconds=15)
def task_gravar_raw_associacoes(blocos: list[BlocoAssociacoes]) -> list[str | None]:
    return [gravar_raw_associacoes(b) for b in blocos]


@task
def task_rodar_dbt() -> None:
    rodar_dbt()


@flow(name="pipeline_hubspot_analytics")
def pipeline_hubspot_analytics(
    objetos: list[str] | None = None,
    rodar_transformacao: bool = True,
) -> None:
    """Extrai do HubSpot, grava o raw no S3 e roda o dbt.

    `rodar_transformacao=False` executa só a ingestão — útil para validar
    a escrita no S3 sem depender do dbt.
    """
    log = get_run_logger()
    objetos = objetos or OBJETOS

    if _carregar_credenciais_aws():
        log.info("Credenciais AWS carregadas do bloco '%s'", AWS_CREDENTIALS_BLOCK)
    else:
        log.info("Bloco de credenciais ausente — usando a cadeia padrão do boto3")

    store = WatermarkStore()

    blocos: list[BlocoExtraido] = []
    for obj in objetos:
        wm = store.get(obj)
        log.info("[%s] watermark atual: %s", obj, wm or "(nenhum — carga full)")
        bloco = task_extrair(obj, wm)
        destino = task_gravar_raw(bloco)
        log.info("[%s] raw gravado em %s", obj, destino or "(nada a gravar)")
        task_gravar_raw_associacoes(task_resolver_associacoes(bloco))
        blocos.append(bloco)

    if not any(not b.vazio for b in blocos):
        log.info("Nenhum registro novo em nenhum objeto — dbt não executado")
    elif rodar_transformacao:
        task_rodar_dbt()
    else:
        log.info("rodar_transformacao=False — dbt pulado")

    for bloco in blocos:
        if bloco.novo_watermark:
            store.set(bloco.object_type, bloco.novo_watermark)
            log.info(
                "[%s] watermark avançado para %s (%d registros, %d invocações)",
                bloco.object_type, bloco.novo_watermark,
                len(bloco.records), bloco.invocacoes,
            )


if __name__ == "__main__":
    pipeline_hubspot_analytics()