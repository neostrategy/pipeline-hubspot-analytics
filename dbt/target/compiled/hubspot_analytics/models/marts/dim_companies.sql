

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

from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__companies"


where updated_at > (
    select coalesce(max(updated_at), timestamp '1970-01-01')
    from "awsdatacatalog"."samsung_hubspot_mart"."dim_companies"
)
