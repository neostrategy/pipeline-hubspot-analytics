
        
            delete from "lake_catalog"."main_gold"."analytics_deals"
            where (
                deal_id) in (
                select (deal_id)
                from "analytics_deals__dbt_tmp20260909110642269797"
            );

        
    

    insert into "lake_catalog"."main_gold"."analytics_deals" ("deal_id", "deal_name", "pipeline_id", "stage_id", "produto_de_interesse", "qualificado_para", "direcionado", "no_bo", "amount", "owner_id", "deal_type", "created_at", "updated_at", "close_date", "primary_contact_id", "company_id", "is_won", "is_closed", "_loaded_at")
    (
        select "deal_id", "deal_name", "pipeline_id", "stage_id", "produto_de_interesse", "qualificado_para", "direcionado", "no_bo", "amount", "owner_id", "deal_type", "created_at", "updated_at", "close_date", "primary_contact_id", "company_id", "is_won", "is_closed", "_loaded_at"
        from "analytics_deals__dbt_tmp20260909110642269797"
    )
  