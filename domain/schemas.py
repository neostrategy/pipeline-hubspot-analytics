"""Contratos de dados do pipeline (padrão: dataclasses como contrato)."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class BlocoExtraido:
    """Resultado consolidado da extração de um objeto em uma execução."""

    object_type: str
    records: list[dict] = field(default_factory=list)
    novo_watermark: str | None = None   # maior lastmodified visto no bloco
    invocacoes: int = 0

    @property
    def vazio(self) -> bool:
        return not self.records

    @property
    def ids(self) -> list[str]:
        return [str(r["id"]) for r in self.records if r.get("id")]


@dataclass
class BlocoAssociacoes:
    """Pares de associação resolvidos para os IDs de uma janela."""

    from_object: str
    to_object: str
    pairs: list[dict] = field(default_factory=list)   # {from_id, to_id, type}
    invocacoes: int = 0

    @property
    def vazio(self) -> bool:
        return not self.pairs
