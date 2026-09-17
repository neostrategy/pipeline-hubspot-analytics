
      merge into "awsdatacatalog"."samsung_hubspot_stg"."snap_hubspot__contact_attribution" as dbt_internal_dest
    using "awsdatacatalog"."samsung_hubspot_stg"."snap_hubspot__contact_attribution__dbt_tmp" as dbt_internal_source
    on dbt_internal_source.dbt_scd_id = dbt_internal_dest.dbt_scd_id

    when matched
     and dbt_internal_dest.dbt_valid_to is null
     and dbt_internal_source.dbt_change_type in ('update', 'delete')
        then update
        set dbt_valid_to = dbt_internal_source.dbt_valid_to

    when not matched
     and dbt_internal_source.dbt_change_type = 'insert'
        then insert ("contact_id", "latest_source", "latest_source_at", "campaign_name", "campaign_type", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "original_source", "updated_at", "dbt_updated_at", "dbt_valid_from", "dbt_valid_to", "dbt_scd_id")
        values (dbt_internal_source."contact_id", dbt_internal_source."latest_source", dbt_internal_source."latest_source_at", dbt_internal_source."campaign_name", dbt_internal_source."campaign_type", dbt_internal_source."utm_source", dbt_internal_source."utm_medium", dbt_internal_source."utm_campaign", dbt_internal_source."utm_content", dbt_internal_source."utm_term", dbt_internal_source."original_source", dbt_internal_source."updated_at", dbt_internal_source."dbt_updated_at", dbt_internal_source."dbt_valid_from", dbt_internal_source."dbt_valid_to", dbt_internal_source."dbt_scd_id")

  