

select
    company_id,
    company_name,
    domain,
    cnpj,
    owner_id,
    created_at,
    updated_at,
    _loaded_at
from "lake_catalog"."main_staging"."stg_hubspot__companies"


where updated_at > (select coalesce(max(updated_at), timestamp '1970-01-01') from "lake_catalog"."main_gold"."analytics_companies")
