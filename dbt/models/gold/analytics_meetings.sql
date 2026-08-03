{{ config(materialized='incremental', unique_key='meeting_id') }}

select
    meeting_id,
    owner_id,
    title,
    outcome,
    location,
    starts_at,
    ends_at,
    occurred_at,
    created_at,
    updated_at,
    _loaded_at
from {{ ref('stg_hubspot__meetings') }}

{% if is_incremental() %}
where updated_at > (select coalesce(max(updated_at), timestamp '1970-01-01') from {{ this }})
{% endif %}
