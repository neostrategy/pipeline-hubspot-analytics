{{
    config(
        materialized = 'incremental',
        table_type = 'iceberg',
        unique_key = 'call_id',
        incremental_strategy = 'merge',
        tags = ['hubspot']
    )
}}

with raw as (

    select *
    from {{ source('hubspot_raw', 'calls') }}

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
    cast(id as bigint)                          as call_id,
    hs_call_title                               as call_title,
    hs_call_body                                as call_body,
    hs_call_direction                           as call_direction,
    hs_call_status                              as call_status,
    hs_call_disposition                         as call_disposition,
    hs_call_recording_url                       as recording_url,
    try_cast(hs_call_duration as bigint)        as call_duration_ms,
    try_cast(hubspot_owner_id as bigint)        as owner_id,

    {{ utc_timestamp('hs_timestamp') }}         as occurred_at,
    {{ utc_timestamp('hs_createdate') }}        as created_at,
    {{ utc_timestamp('hs_lastmodifieddate') }}  as updated_at,
    {{ utc_timestamp('load_ts') }}              as _loaded_at

from dedup
where _rn = 1