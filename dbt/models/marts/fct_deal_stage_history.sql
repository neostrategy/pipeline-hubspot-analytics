{{
    config(
        materialized = 'table',
        table_type = 'iceberg',
        tags = ['hubspot']
    )
}}

with versoes as (

    select
        deal_id,
        pipeline_id,
        deal_stage,
        deal_amount,
        owner_id,
        cast(dbt_valid_from as timestamp(6))    as valid_from,
        cast(dbt_valid_to   as timestamp(6))    as valid_to
    from {{ ref('snap_hubspot__deal_stage') }}

),

numeradas as (

    select
        *,
        row_number() over (
            partition by deal_id
            order by valid_from
        )                                       as stage_number,
        lag(deal_stage) over (
            partition by deal_id
            order by valid_from
        )                                       as previous_deal_stage
    from versoes

)

select
    deal_id,
    pipeline_id,
    deal_stage,
    previous_deal_stage,
    stage_number,
    deal_amount,
    owner_id,
    valid_from,
    valid_to,
    valid_to is null                            as is_current_stage,
    cast(round(
        date_diff('second', valid_from, coalesce(valid_to, current_timestamp))
        / 3600.0, 2
    ) as decimal(12,2))                         as duration_hours
from numeradas