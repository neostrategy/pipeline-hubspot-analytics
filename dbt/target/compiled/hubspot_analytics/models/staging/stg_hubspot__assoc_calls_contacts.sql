



with raw as (

    select *
    from "awsdatacatalog"."samsung_hubspot_raw"."assoc_calls_contacts"

    
    where dt >= (
        select coalesce(max(date_format(_loaded_at, '%Y-%m-%d')), '1900-01-01')
        from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__assoc_calls_contacts"
    )
    

),

dedup as (

    select *,
           row_number() over (
               partition by from_id, to_id
               order by load_ts desc
           ) as _rn
    from raw

)

select
    cast(from_id as bigint)             as from_id,
    cast(to_id as bigint)               as to_id,
    type                                as assoc_type,
    try(cast(from_iso8601_timestamp(load_ts) as timestamp(6)))      as _loaded_at
from dedup
where _rn = 1

