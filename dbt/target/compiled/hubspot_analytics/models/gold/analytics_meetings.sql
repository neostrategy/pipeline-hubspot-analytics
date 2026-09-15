

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
from "lake_catalog"."main_staging"."stg_hubspot__meetings"


where updated_at > (select coalesce(max(updated_at), timestamp '1970-01-01') from "lake_catalog"."main_gold"."analytics_meetings")
