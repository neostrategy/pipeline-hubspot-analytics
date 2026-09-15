
        
            delete from "lake_catalog"."main_gold"."analytics_contacts"
            where (
                contact_id) in (
                select (contact_id)
                from "analytics_contacts__dbt_tmp20260909110630687668"
            );

        
    

    insert into "lake_catalog"."main_gold"."analytics_contacts" ("contact_id", "email", "first_name", "last_name", "phone", "cargo", "produto_de_interesse", "lifecycle_stage", "lead_status", "owner_id", "original_source", "latest_source", "latest_source_at", "origem_analytics", "origem_detalhe_1", "origem_detalhe_2", "primeira_url", "ultima_url", "criacao_origem_label", "criacao_detalhe_1", "criacao_detalhe_2", "criacao_detalhe_3", "clicou_linkedin_ad", "gclid", "fbclid", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "campanha", "tipo_de_campanha", "created_at", "updated_at", "_loaded_at")
    (
        select "contact_id", "email", "first_name", "last_name", "phone", "cargo", "produto_de_interesse", "lifecycle_stage", "lead_status", "owner_id", "original_source", "latest_source", "latest_source_at", "origem_analytics", "origem_detalhe_1", "origem_detalhe_2", "primeira_url", "ultima_url", "criacao_origem_label", "criacao_detalhe_1", "criacao_detalhe_2", "criacao_detalhe_3", "clicou_linkedin_ad", "gclid", "fbclid", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "campanha", "tipo_de_campanha", "created_at", "updated_at", "_loaded_at"
        from "analytics_contacts__dbt_tmp20260909110630687668"
    )
  