{{
    config(
        materialized = 'incremental',
        table_type = 'iceberg',
        unique_key = 'meeting_id',
        incremental_strategy = 'merge',
        tags = ['hubspot']
    )
}}

with raw as (

    select *
    from {{ source('hubspot_raw', 'meetings') }}

    {% if is_incremental() %}
    where dt >= (
        select coalesce(max(date_format(_loaded_at, '%Y-%m-%d')), '1900-01-01')
        from {{ this }}
    )
    {% endif %}

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

    {{ utc_timestamp('hs_meeting_start_time') }} as started_at,
    {{ utc_timestamp('hs_meeting_end_time') }}   as ended_at,
    {{ utc_timestamp('hs_timestamp') }}          as occurred_at,
    {{ utc_timestamp('hs_createdate') }}         as created_at,
    {{ utc_timestamp('hs_lastmodifieddate') }}   as updated_at,
    {{ utc_timestamp('load_ts') }}               as _loaded_at

from dedup
where _rn = 1