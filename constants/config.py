"""Configuração do pipeline — único lugar com valores de ambiente/negócio."""

import os
from pathlib import Path

# --- AWS -----------------------------------------------------------------
AWS_REGION = "sa-east-1"
LAMBDA_FUNCTION = "hubspot-api-lambda"

# --- Armazenamento local -------------------------------------------------
DUCKDB_PATH = os.environ.get("DUCKDB_PATH", "data/analytics.duckdb")
RAW_DIR = Path(os.environ.get("HUBSPOT_RAW_DIR", "data/raw/hubspot"))

# --- Objetos e propriedades ----------------------------------------------
OBJETOS = ["contacts", "companies", "deals", "calls", "meetings"]

# Propriedade de última modificação (exceção histórica: contacts sem prefixo)
LASTMOD = {"contacts": "lastmodifieddate"}
LASTMOD_DEFAULT = "hs_lastmodifieddate"

# Associações a resolver por objeto (a Search API não devolve associations,
# então o flow chama a action `associations` com os IDs da janela).
ASSOCIACOES: dict[str, list[str]] = {
    "deals": ["contacts", "companies"],
    "calls": ["contacts", "deals", "companies"],
    "meetings": ["contacts", "deals", "companies"],
}
# IDs por invocação da action associations (o Lambda fatia de 100 em 100)
ASSOC_IDS_POR_INVOCACAO = 500

# --- Limites de segurança ------------------------------------------------
# Cursor da Search API estoura em 10.000; fatiamos a janela antes disso
SEARCH_CURSOR_SAFETY = 9_500
# Freio de emergência: invocações do Lambda por objeto por execução
MAX_INVOCACOES = 50

# --- dbt -----------------------------------------------------------------
DBT_SELECT = "tag:hubspot"
DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", "dbt")
