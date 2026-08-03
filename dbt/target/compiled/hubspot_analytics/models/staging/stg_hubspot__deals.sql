

with raw as (

    select *
    from read_json_auto(
        'data/raw/hubspot/deals/*.jsonl',
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
    cast(id as bigint)                                  as deal_id,
    dealname                                            as deal_name,
    pipeline                                            as pipeline_id,
    dealstage                                           as stage_id,
    try_cast(amount as decimal(15, 2))                  as amount,
    try_cast(hubspot_owner_id as bigint)                    as owner_id,
    dealtype                                            as deal_type,
    try_cast(createdate as timestamp)                       as created_at,
    try_cast(hs_lastmodifieddate as timestamp)              as updated_at,
    try_cast(closedate as timestamp)                        as close_date,
    try_cast(load_ts as timestamp)                          as _loaded_at
from dedup
where _rn = 1