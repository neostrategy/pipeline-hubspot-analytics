

with raw as (

    select *
    from "awsdatacatalog"."samsung_hubspot_raw"."calls"

    
    where dt >= (
        select coalesce(max(date_format(_loaded_at, '%Y-%m-%d')), '1900-01-01')
        from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__calls"
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
    cast(id as bigint)                          as call_id,
    hs_call_title                               as call_title,
    hs_call_body                                as call_body,
    hs_call_direction                           as call_direction,
    hs_call_status                              as call_status,
    hs_call_disposition                         as call_disposition,
    hs_call_recording_url                       as recording_url,
    try_cast(hs_call_duration as bigint)        as call_duration_ms,
    try_cast(hubspot_owner_id as bigint)        as owner_id,

    try(cast(from_iso8601_timestamp(hs_timestamp) as timestamp(6)))         as occurred_at,
    try(cast(from_iso8601_timestamp(hs_createdate) as timestamp(6)))        as created_at,
    try(cast(from_iso8601_timestamp(hs_lastmodifieddate) as timestamp(6)))  as updated_at,
    try(cast(from_iso8601_timestamp(load_ts) as timestamp(6)))              as _loaded_at

from dedup
where _rn = 1