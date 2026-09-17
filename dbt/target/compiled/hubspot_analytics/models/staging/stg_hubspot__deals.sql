

with raw as (

    select *
    from "awsdatacatalog"."samsung_hubspot_raw"."deals"

    
    where dt >= (
        select coalesce(max(date_format(_loaded_at, '%Y-%m-%d')), '1900-01-01')
        from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__deals"
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
    cast(id as bigint)                                      as deal_id,
    dealname                                                as deal_name,
    description,
    try_cast(hubspot_owner_id as bigint)                    as owner_id,

    -- funil
    pipeline                                                as pipeline_id,
    dealstage                                               as deal_stage,
    dealtype                                                as deal_type,
    hs_forecast_category                                    as forecast_category,
    try_cast(hs_deal_stage_probability as decimal(9, 6))    as stage_probability_ratio,
    hs_next_step                                            as next_step,

    -- valores
    try_cast(amount as decimal(18, 2))                      as deal_amount,
    try_cast(hs_closed_amount as decimal(18, 2))            as closed_amount,
    try_cast(hs_projected_amount as decimal(18, 2))         as projected_amount,

    -- classificacao comercial
    categoria_de_produto_de_interesse                       as product_category_interest,

    -- termos de negocio preservados
    no_bo,
    direcionado,
    qualificado_para_qual_funil,

    try(cast(from_iso8601_timestamp(closedate) as timestamp(6)))                        as closed_at,
    try(cast(from_iso8601_timestamp(createdate) as timestamp(6)))                       as created_at,
    try(cast(from_iso8601_timestamp(hs_lastmodifieddate) as timestamp(6)))              as updated_at,
    try(cast(from_iso8601_timestamp(load_ts) as timestamp(6)))                          as _loaded_at

from dedup
where _rn = 1