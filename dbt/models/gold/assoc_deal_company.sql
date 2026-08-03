{{ config(materialized='table') }}

select
    from_id     as deal_id,
    to_id       as company_id,
    assoc_type,
    _loaded_at
from {{ ref('stg_assoc__deals_companies') }}
