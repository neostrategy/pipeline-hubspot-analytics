
  
  create view "analytics"."main_staging"."stg_hubspot__calls__dbt_tmp" as (
    

with raw as (

    select *
    from read_json_auto(
        'data/raw/hubspot/calls/*.jsonl',
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
    cast(id as bigint)                                  as call_id,
    try_cast(hubspot_owner_id as bigint)                    as owner_id,
    hs_call_title                                       as title,
    hs_call_direction                                   as direction,
    hs_call_disposition                                 as disposition,
    hs_call_status                                      as status,
    try_cast(hs_call_duration as integer)               as duration_ms,
    try_cast(hs_timestamp as timestamp)                     as occurred_at,
    try_cast(hs_createdate as timestamp)                    as created_at,
    try_cast(hs_lastmodifieddate as timestamp)              as updated_at,
    try_cast(load_ts as timestamp)                          as _loaded_at
from dedup
where _rn = 1
  );
