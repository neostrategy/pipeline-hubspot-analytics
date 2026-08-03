{{ config(materialized='incremental', unique_key='call_id') }}

select
    call_id,
    owner_id,
    title,
    direction,
    disposition,
    status,
    duration_ms,
    occurred_at,
    created_at,
    updated_at,
    _loaded_at
from {{ ref('stg_hubspot__calls') }}

{% if is_incremental() %}
where updated_at > (select coalesce(max(updated_at), timestamp '1970-01-01') from {{ this }})
{% endif %}
