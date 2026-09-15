
  
  create view "lake_catalog"."main_staging"."stg_hubspot__contacts__dbt_tmp" as (
    

with raw as (

    select *
    from read_json_auto(
        'data/raw/hubspot/contacts/*.jsonl',
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
    cast(id as bigint)                                  as contact_id,
    email,
    firstname                                           as first_name,
    lastname                                            as last_name,
    phone,
    cargo,
    produto_de_interesse,
    lifecyclestage                                      as lifecycle_stage,
    hs_lead_status                                      as lead_status,
    try_cast(hubspot_owner_id as bigint)                    as owner_id,
    hs_analytics_source                                 as original_source,
    hs_latest_source                                    as latest_source,
    hs_analytics_source                                 as origem_analytics,
    hs_analytics_source_data_1                          as origem_detalhe_1,
    hs_analytics_source_data_2                          as origem_detalhe_2,
    hs_analytics_first_url                              as primeira_url,
    hs_analytics_last_url                               as ultima_url,
    hs_object_source_label                              as criacao_origem_label,
    hs_object_source_detail_1                           as criacao_detalhe_1,
    hs_object_source_detail_2                           as criacao_detalhe_2,
    hs_object_source_detail_3                           as criacao_detalhe_3,
    hs_clicked_linkedin_ad                              as clicou_linkedin_ad,
    hs_google_click_id                                  as gclid,
    hs_facebook_click_id                                as fbclid,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    campanha,
    tipo_de_campanha,
    try_cast(hs_latest_source_timestamp as timestamp)       as latest_source_at,
    try_cast(createdate as timestamp)                       as created_at,
    try_cast(lastmodifieddate as timestamp)                 as updated_at,
    try_cast(load_ts as timestamp)                          as _loaded_at
from dedup
where _rn = 1
  );
