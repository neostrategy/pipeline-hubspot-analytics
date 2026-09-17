

select
    meeting_id,
    owner_id,
    meeting_title,
    meeting_location,
    meeting_outcome,
    started_at,
    ended_at,
    cast(round(date_diff('second', started_at, ended_at) / 60.0, 2) as decimal(12,2))
                                                             as meeting_duration_minutes,
    occurred_at,
    cast(occurred_at as date)               as occurred_date,
    created_at,
    updated_at,
    _loaded_at

from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__meetings"


where updated_at > (
    select coalesce(max(updated_at), timestamp '1970-01-01')
    from "awsdatacatalog"."samsung_hubspot_mart"."fct_meetings"
)
