"""Persistência do cursor incremental por objeto.

Implementação em DynamoDB, mantendo a interface (get / set) da versão
anterior em DuckDB — o resto do pipeline não muda.

A escrita é condicional: o watermark só avança se o novo valor for maior
que o gravado. Isso impede que uma execução mais lenta sobrescreva o
cursor de uma mais recente e faça o pipeline pular registros.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

from constants.config import AWS_REGION, WATERMARK_PIPELINE, WATERMARK_TABLE

log = logging.getLogger(__name__)


class WatermarkStore:
    def __init__(
        self,
        table_name: str = WATERMARK_TABLE,
        pipeline: str = WATERMARK_PIPELINE,
        region: str = AWS_REGION,
    ):
        self.pipeline = pipeline
        self.table = boto3.resource("dynamodb", region_name=region).Table(table_name)

    def get(self, object_type: str) -> str | None:
        resposta = self.table.get_item(
            Key={"pipeline": self.pipeline, "object_type": object_type},
            ConsistentRead=True,
        )
        item = resposta.get("Item")
        return item["watermark"] if item else None

    def set(self, object_type: str, watermark: str) -> None:
        try:
            self.table.put_item(
                Item={
                    "pipeline": self.pipeline,
                    "object_type": object_type,
                    "watermark": watermark,
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                },
                ConditionExpression=(
                    "attribute_not_exists(watermark) OR watermark < :novo"
                ),
                ExpressionAttributeValues={":novo": watermark},
            )
        except ClientError as erro:
            if erro.response["Error"]["Code"] != "ConditionalCheckFailedException":
                raise
            log.warning(
                "[%s] watermark %s ignorado — o gravado já é mais recente",
                object_type,
                watermark,
            )

    def reset(self, object_type: str) -> None:
        """Apaga o cursor para forçar carga histórica completa no próximo run."""
        self.table.delete_item(
            Key={"pipeline": self.pipeline, "object_type": object_type}
        )