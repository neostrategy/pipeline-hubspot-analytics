

with raw as (

    select *
    from "awsdatacatalog"."samsung_hubspot_raw"."meetings"

    
    where dt >= (
        select coalesce(max(date_format(_loaded_at, '%Y-%m-%d')), '1900-01-01')
        from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__meetings"
    )
    

),

dedup as (

    select *,
           row_number() over (
               partition by id
               order by load_ts desc
           ) as _rn
    from raw

)

select
    cast(id as bigint)                          as meeting_id,
    hs_meeting_title                            as meeting_title,
    hs_meeting_body                             as meeting_body,
    hs_meeting_location                         as meeting_location,
    hs_meeting_outcome                          as meeting_outcome,
    try_cast(hubspot_owner_id as bigint)        as owner_id,

    try(cast(from_iso8601_timestamp(hs_meeting_start_time) as timestamp(6))) as started_at,
    try(cast(from_iso8601_timestamp(hs_meeting_end_time) as timestamp(6)))   as ended_at,
    try(cast(from_iso8601_timestamp(hs_timestamp) as timestamp(6)))          as occurred_at,
    try(cast(from_iso8601_timestamp(hs_createdate) as timestamp(6)))         as created_at,
    try(cast(from_iso8601_timestamp(hs_lastmodifieddate) as timestamp(6)))   as updated_at,
    try(cast(from_iso8601_timestamp(load_ts) as timestamp(6)))               as _loaded_at

from dedup
where _rn = 1