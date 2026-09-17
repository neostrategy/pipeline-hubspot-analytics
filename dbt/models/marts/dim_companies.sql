{{
    config(
        materialized = 'incremental',
        table_type = 'iceberg',
        unique_key = 'company_id',
        incremental_strategy = 'merge',
        tags = ['hubspot']
    )
}}

select
    company_id,
    company_name,
    cnpj,
    domain,
    website_url,
    linkedin_url,
    phone,
    description,

    company_type,
    industry,
    lifecycle_stage,
    lead_status,
    owner_id,

    employees_qty,
    annual_revenue_amount,

    city,
    state,
    country,
    postal_code,

    created_at,
    updated_at,
    _loaded_at

from {{ ref('stg_hubspot__companies') }}

{% if is_incremental() %}
where updated_at > (
    select coalesce(max(updated_at), timestamp '1970-01-01')
    from {{ this }}
)
{% endif %}