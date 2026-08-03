{{ config(materialized='incremental', unique_key='contact_id') }}

select
    contact_id,
    email,
    first_name,
    last_name,
    phone,
    lifecycle_stage,
    lead_status,
    owner_id,
    original_source,     -- first-touch (imutável no HubSpot)
    latest_source,       -- last-touch (sobrescrita a cada interação)
    latest_source_at,
    origem_analytics,
    origem_detalhe_1,
    origem_detalhe_2,
    primeira_url,
    ultima_url,
    criacao_origem_label,
    criacao_detalhe_1,
    criacao_detalhe_2,
    criacao_detalhe_3,
    clicou_linkedin_ad,
    gclid,
    fbclid,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    created_at,
    updated_at,
    _loaded_at
from {{ ref('stg_hubspot__contacts') }}

{% if is_incremental() %}
where updated_at > (select coalesce(max(updated_at), timestamp '1970-01-01') from {{ this }})
{% endif %}
