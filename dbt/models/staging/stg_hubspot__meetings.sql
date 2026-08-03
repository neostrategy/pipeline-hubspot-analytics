{{ config(materialized='view') }}

with raw as (

    select *
    from read_json_auto(
        '{{ env_var("HUBSPOT_RAW_DIR", "data/raw/hubspot") }}/meetings/*.jsonl',
        union_by_name = true
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
    cast(id as bigint)                                  as meeting_id,
    try_cast(hubspot_owner_id as bigint)                    as owner_id,
    hs_meeting_title                                    as title,
    hs_meeting_outcome                                  as outcome,
    hs_meeting_location                                 as location,
    try_cast(hs_meeting_start_time as timestamp)            as starts_at,
    try_cast(hs_meeting_end_time as timestamp)              as ends_at,
    try_cast(hs_timestamp as timestamp)                     as occurred_at,
    try_cast(hs_createdate as timestamp)                    as created_at,
    try_cast(hs_lastmodifieddate as timestamp)              as updated_at,
    try_cast(load_ts as timestamp)                          as _loaded_at
from dedup
where _rn = 1
