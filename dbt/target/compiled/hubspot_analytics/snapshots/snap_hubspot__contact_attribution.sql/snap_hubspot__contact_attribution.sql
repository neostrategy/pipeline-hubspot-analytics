



select
    contact_id,
    latest_source,
    latest_source_at,
    campaign_name,
    campaign_type,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    original_source,
    updated_at
from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__contacts"
