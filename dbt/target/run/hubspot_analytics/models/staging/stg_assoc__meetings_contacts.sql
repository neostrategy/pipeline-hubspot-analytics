
  
  create view "lake_catalog"."main_staging"."stg_assoc__meetings_contacts__dbt_tmp" as (
    


with raw as (

    select *
    from read_json_auto(
        'data/raw/hubspot/assoc_meetings_contacts/*.jsonl',
        union_by_name = true
    )

),

dedup as (

    select *,
           row_number() over (
               partition by from_id, to_id order by load_ts desc
           ) as _rn
    from raw

)

select
    cast(from_id as bigint)         as from_id,
    cast(to_id as bigint)           as to_id,
    cast(type as varchar)           as assoc_type,
    try_cast(load_ts as timestamp)  as _loaded_at
from dedup
where _rn = 1


  );
