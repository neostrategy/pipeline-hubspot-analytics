

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
from "analytics"."main_staging"."stg_hubspot__meetings"


where updated_at > (select coalesce(max(updated_at), timestamp '1970-01-01') from "analytics"."main_gold"."analytics_meetings")
