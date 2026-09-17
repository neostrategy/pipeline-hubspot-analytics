
      merge into "awsdatacatalog"."samsung_hubspot_stg"."snap_hubspot__deal_stage" as dbt_internal_dest
    using "awsdatacatalog"."samsung_hubspot_stg"."snap_hubspot__deal_stage__dbt_tmp" as dbt_internal_source
    on dbt_internal_source.dbt_scd_id = dbt_internal_dest.dbt_scd_id

    when matched
     and dbt_internal_dest.dbt_valid_to is null
     and dbt_internal_source.dbt_change_type in ('update', 'delete')
        then update
        set dbt_valid_to = dbt_internal_source.dbt_valid_to

    when not matched
     and dbt_internal_source.dbt_change_type = 'insert'
        then insert ("deal_id", "pipeline_id", "deal_stage", "deal_amount", "owner_id", "updated_at", "dbt_updated_at", "dbt_valid_from", "dbt_valid_to", "dbt_scd_id")
        values (dbt_internal_source."deal_id", dbt_internal_source."pipeline_id", dbt_internal_source."deal_stage", dbt_internal_source."deal_amount", dbt_internal_source."owner_id", dbt_internal_source."updated_at", dbt_internal_source."dbt_updated_at", dbt_internal_source."dbt_valid_from", dbt_internal_source."dbt_valid_to", dbt_internal_source."dbt_scd_id")

  