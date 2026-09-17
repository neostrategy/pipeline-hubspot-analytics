

with raw as (

    select *
    from "awsdatacatalog"."samsung_hubspot_raw"."contacts"

    
    -- le apenas as particoes gravadas desde a ultima carga
    where dt >= (
        select coalesce(max(date_format(_loaded_at, '%Y-%m-%d')), '1900-01-01')
        from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__contacts"
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
    cast(id as bigint)                                  as contact_id,
    email,
    firstname                                           as first_name,
    lastname                                            as last_name,
    phone,
    mobilephone                                         as mobile_phone,
    cargo                                               as job_title,
    produto_de_interesse                                as product_interest,
    lifecyclestage                                      as lifecycle_stage,
    hs_lead_status                                      as lead_status,
    try_cast(hubspot_owner_id as bigint)                as owner_id,
    try_cast(associatedcompanyid as bigint)             as company_id,

    -- atribuicao de origem
    hs_analytics_source                                 as original_source,
    hs_analytics_source_data_1                          as original_source_detail_1,
    hs_analytics_source_data_2                          as original_source_detail_2,
    hs_latest_source                                    as latest_source,
    hs_analytics_first_url                              as first_touch_url,
    hs_analytics_last_url                               as last_touch_url,

    -- origem do registro no CRM
    hs_object_source_label                              as record_source_label,
    hs_object_source_detail_1                           as record_source_detail_1,
    hs_object_source_detail_2                           as record_source_detail_2,
    hs_object_source_detail_3                           as record_source_detail_3,

    -- midia paga
    hs_clicked_linkedin_ad                              as linkedin_ad_click_id,
    hs_google_click_id                                  as gclid,
    hs_facebook_click_id                                as fbclid,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    campanha                                            as campaign_name,
    tipo_de_campanha                                    as campaign_type,

    -- conversao
    first_conversion_event_name,
    try_cast(num_conversion_events as integer)          as conversion_events_qty,
    try_cast(num_unique_conversion_events as integer)   as unique_conversion_events_qty,
    try(cast(from_iso8601_timestamp(first_conversion_date) as timestamp(6)))        as first_converted_at,

    -- termos de negocio preservados
    cadastrado_canal_azul,

    try(cast(from_iso8601_timestamp(hs_latest_source_timestamp) as timestamp(6)))   as latest_source_at,
    try(cast(from_iso8601_timestamp(createdate) as timestamp(6)))                   as created_at,
    try(cast(from_iso8601_timestamp(lastmodifieddate) as timestamp(6)))             as updated_at,
    try(cast(from_iso8601_timestamp(load_ts) as timestamp(6)))                      as _loaded_at

from dedup
where _rn = 1