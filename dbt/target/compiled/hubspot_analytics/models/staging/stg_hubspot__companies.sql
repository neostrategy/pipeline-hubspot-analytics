

with raw as (

    select *
    from "awsdatacatalog"."samsung_hubspot_raw"."companies"

    
    where dt >= (
        select coalesce(max(date_format(_loaded_at, '%Y-%m-%d')), '1900-01-01')
        from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__companies"
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
    cast(id as bigint)                                  as company_id,
    name                                                as company_name,
    cnpj,
    domain,
    website                                             as website_url,
    linkedin_company_page                               as linkedin_url,
    phone,
    description,

    -- classificacao
    type                                                as company_type,
    industry,
    lifecyclestage                                      as lifecycle_stage,
    hs_lead_status                                      as lead_status,
    try_cast(hubspot_owner_id as bigint)                as owner_id,

    -- porte
    try_cast(numberofemployees as integer)              as employees_qty,
    try_cast(annualrevenue as decimal(18, 2))           as annual_revenue_amount,

    -- localizacao
    city,
    state,
    country,
    zip                                                 as postal_code,

    try(cast(from_iso8601_timestamp(createdate) as timestamp(6)))                   as created_at,
    try(cast(from_iso8601_timestamp(hs_lastmodifieddate) as timestamp(6)))          as updated_at,
    try(cast(from_iso8601_timestamp(load_ts) as timestamp(6)))                      as _loaded_at

from dedup
where _rn = 1