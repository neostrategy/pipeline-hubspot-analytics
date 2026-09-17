

select
    call_id,
    owner_id,
    call_title,
    call_direction,
    call_disposition,
    call_status,
    call_duration_ms,
    cast(round(call_duration_ms / 60000.0, 2) as decimal(12,2))  as call_duration_minutes,
    occurred_at,
    cast(occurred_at as date)               as occurred_date,
    created_at,
    updated_at,
    _loaded_at

from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__calls"


where updated_at > (
    select coalesce(max(updated_at), timestamp '1970-01-01')
    from "awsdatacatalog"."samsung_hubspot_mart"."fct_calls"
)
