{{
    config(
        materialized = 'incremental',
        table_type = 'iceberg',
        unique_key = 'contact_id',
        incremental_strategy = 'merge',
        tags = ['hubspot']
    )
}}

with contatos as (

    select * from {{ ref('stg_hubspot__contacts') }}

),

importacoes as (

    /*
        Importacao em lote cria muitos contatos no mesmo minuto, o que gera
        um pico artificial em analise de coorte. Detectamos pelo volume por
        minuto de criacao para o BI poder filtrar.

        Avaliado sobre a base inteira, nao apenas sobre a janela incremental
        — senao um lote dividido entre duas execucoes passaria despercebido.
    */
    select date_trunc('minute', created_at) as minuto_criacao
    from {{ ref('stg_hubspot__contacts') }}
    group by 1
    having count(*) >= 20

)

select
    c.contact_id,
    c.email,
    c.first_name,
    c.last_name,
    trim(coalesce(c.first_name, '') || ' ' || coalesce(c.last_name, ''))
                                                as full_name,
    c.phone,
    c.mobile_phone,
    c.job_title,
    c.product_interest,
    c.lifecycle_stage,
    c.lead_status,
    c.owner_id,
    c.company_id,

    -- atribuicao de origem
    c.original_source,            -- first touch, imutavel no HubSpot
    c.original_source_detail_1,
    c.original_source_detail_2,
    c.latest_source,              -- last touch, sobrescrita a cada interacao
    c.latest_source_at,
    c.first_touch_url,
    c.last_touch_url,

    -- origem do registro no CRM
    c.record_source_label,
    c.record_source_detail_1,
    c.record_source_detail_2,
    c.record_source_detail_3,

    -- midia paga
    c.linkedin_ad_click_id,
    c.gclid,
    c.fbclid,
    c.gclid is not null and c.gclid <> ''       as has_google_ads_click,
    c.fbclid is not null and c.fbclid <> ''     as has_meta_ads_click,
    c.utm_source,
    c.utm_medium,
    c.utm_campaign,
    c.utm_content,
    c.utm_term,
    c.campaign_name,
    c.campaign_type,

    -- conversao
    c.first_conversion_event_name,
    c.conversion_events_qty,
    c.unique_conversion_events_qty,
    c.first_converted_at,

    c.cadastrado_canal_azul,

    -- ruido de coorte: contatos criados por importacao em lote
    i.minuto_criacao is not null
        or upper(coalesce(c.original_source, '')) = 'OFFLINE'
                                                as is_bulk_import,

    c.created_at,
    cast(c.created_at as date)                  as created_date,
    c.updated_at,
    c._loaded_at

from contatos c
left join importacoes i
       on date_trunc('minute', c.created_at) = i.minuto_criacao

{% if is_incremental() %}
where c.updated_at > (
    select coalesce(max(updated_at), timestamp '1970-01-01')
    from {{ this }}
)
{% endif %}