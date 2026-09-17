"""Configuração do pipeline — único lugar com valores de ambiente/negócio."""

import os

from dotenv import load_dotenv

load_dotenv()

# --- AWS -----------------------------------------------------------------
AWS_REGION = "sa-east-1"
LAMBDA_FUNCTION = "hubspot-api-lambda"

# --- Lake (S3) -----------------------------------------------------------
RAW_BUCKET = os.environ.get("RAW_BUCKET", "neotass-lake-samsung-sa-east-1")
RAW_PREFIX = os.environ.get("RAW_PREFIX", "raw/hubspot")

# --- Glue / Athena -------------------------------------------------------
GLUE_RAW_DATABASE = os.environ.get("GLUE_RAW_DATABASE", "samsung_hubspot_raw")
GLUE_STG_DATABASE = os.environ.get("GLUE_STG_DATABASE", "samsung_hubspot_stg")
GLUE_MART_DATABASE = os.environ.get("GLUE_MART_DATABASE", "samsung_hubspot_mart")
ATHENA_WORKGROUP = os.environ.get("ATHENA_WORKGROUP", "primary")

# --- Watermark (DynamoDB) ------------------------------------------------
WATERMARK_TABLE = os.environ.get("WATERMARK_TABLE", "pipeline-watermarks")
WATERMARK_PIPELINE = "hubspot-analytics"

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
DBT_TARGET = os.environ.get("DBT_TARGET", "prod")
DBT_SELECT = "tag:hubspot"
DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", "dbt")

# --- Manutenção Iceberg --------------------------------------------------
# Glue Data Catalog não compacta sozinho; rodar OPTIMIZE/VACUUM semanalmente.
MANUTENCAO_TABELAS = [
    "dim_contacts",
    "dim_companies",
    "dim_deals",
    "fct_calls",
    "fct_meetings",
    "fct_deal_stage_hist",
    "fct_activities",
    "agg_entradas_mensais",
]