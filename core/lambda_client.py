"""Cliente do hubspot-api-lambda — única fronteira do pipeline com a AWS.

Na máquina com o DLP (GTB Endpoint Protector), exportar o CA raiz e
apontar AWS_CA_BUNDLE/REQUESTS_CA_BUNDLE — mesmo caso do prefect_bo_update.
"""

from __future__ import annotations

import json

import boto3

from constants.config import AWS_REGION, LAMBDA_FUNCTION


class HubspotLambdaClient:
    """Invoca o hubspot-api-lambda e traduz o envelope de resposta."""

    def __init__(self, function_name: str = LAMBDA_FUNCTION,
                 region: str = AWS_REGION):
        self._client = boto3.client("lambda", region_name=region)
        self._function = function_name

    def invocar(self, payload: dict) -> dict:
        """Devolve o body desserializado; levanta erro em statusCode != 200."""
        resp = self._client.invoke(
            FunctionName=self._function,
            Payload=json.dumps(payload).encode(),
        )
        envelope = json.loads(resp["Payload"].read())
        if envelope.get("statusCode") != 200:
            raise RuntimeError(
                f"Lambda retornou {envelope.get('statusCode')}: "
                f"{envelope.get('body')}"
            )
        return json.loads(envelope["body"])
