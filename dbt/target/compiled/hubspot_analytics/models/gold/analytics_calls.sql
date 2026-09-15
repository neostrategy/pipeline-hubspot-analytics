

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
from "lake_catalog"."main_staging"."stg_hubspot__calls"


where updated_at > (select coalesce(max(updated_at), timestamp '1970-01-01') from "lake_catalog"."main_gold"."analytics_calls")
