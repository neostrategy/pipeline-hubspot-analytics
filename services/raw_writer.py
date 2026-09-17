"""Persistência do raw em JSONL no S3.

Layout: s3://<bucket>/<prefix>/hubspot/<objeto>/dt=<YYYY-MM-DD>/<runts>.jsonl

A partição por data permite que o staging filtre no Athena sem escanear
o histórico inteiro a cada execução.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from io import BytesIO

import boto3

from constants.config import AWS_REGION, RAW_BUCKET, RAW_PREFIX
from domain.schemas import BlocoAssociacoes, BlocoExtraido

_s3 = boto3.client("s3", region_name=AWS_REGION)


def _montar_chave(pasta: str, run_dt: datetime) -> str:
    particao = run_dt.strftime("%Y-%m-%d")
    run_ts = run_dt.strftime("%Y%m%dT%H%M%SZ")
    return f"{RAW_PREFIX}/{pasta}/dt={particao}/{run_ts}.jsonl"


def _enviar(chave: str, linhas: list[str]) -> str:
    corpo = BytesIO("\n".join(linhas).encode("utf-8"))
    _s3.upload_fileobj(corpo, RAW_BUCKET, chave)
    return f"s3://{RAW_BUCKET}/{chave}"


def gravar_raw(bloco: BlocoExtraido) -> str | None:
    if bloco.vazio:
        return None

    agora = datetime.now(timezone.utc)
    carimbo = agora.isoformat()
    chave = _montar_chave(bloco.object_type, agora)

    linhas = [
        json.dumps({**r, "load_ts": carimbo}, ensure_ascii=False)
        for r in bloco.records
    ]
    return _enviar(chave, linhas)


def gravar_raw_associacoes(bloco: BlocoAssociacoes) -> str | None:
    """Grava os pares em hubspot/assoc_<from>_<to>/dt=<data>/<runts>.jsonl."""
    if bloco.vazio:
        return None

    agora = datetime.now(timezone.utc)
    carimbo = agora.isoformat()
    pasta = f"assoc_{bloco.from_object}_{bloco.to_object}"
    chave = _montar_chave(pasta, agora)

    linhas = [
        json.dumps({**par, "load_ts": carimbo}, ensure_ascii=False)
        for par in bloco.pairs
    ]
    return _enviar(chave, linhas)