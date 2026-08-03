"""Persistência do raw em JSONL: data/raw/hubspot/<objeto>/<runts>.jsonl.

Pasta local pelo mesmo motivo do prefect_bo_update (DLP); ao habilitar S3,
esta é a única camada que muda.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from constants.config import RAW_DIR
from domain.schemas import BlocoAssociacoes, BlocoExtraido


def gravar_raw(bloco: BlocoExtraido) -> Path | None:
    if bloco.vazio:
        return None
    run_ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    destino = RAW_DIR / bloco.object_type / f"{run_ts}.jsonl"
    destino.parent.mkdir(parents=True, exist_ok=True)
    with destino.open("w", encoding="utf-8") as f:
        for r in bloco.records:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    return destino


def gravar_raw_associacoes(bloco: BlocoAssociacoes) -> Path | None:
    """Grava os pares em data/raw/hubspot/assoc_<from>_<to>/<runts>.jsonl."""
    if bloco.vazio:
        return None
    run_ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    pasta = f"assoc_{bloco.from_object}_{bloco.to_object}"
    destino = RAW_DIR / pasta / f"{run_ts}.jsonl"
    destino.parent.mkdir(parents=True, exist_ok=True)
    carimbo = datetime.now(timezone.utc).isoformat()
    with destino.open("w", encoding="utf-8") as f:
        for par in bloco.pairs:
            f.write(json.dumps({**par, "load_ts": carimbo}, ensure_ascii=False) + "\n")
    return destino
