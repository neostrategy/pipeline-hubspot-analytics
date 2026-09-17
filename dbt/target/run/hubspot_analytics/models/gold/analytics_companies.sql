
        
            delete from "lake_catalog"."main_gold"."analytics_companies"
            where (
                company_id) in (
                select (company_id)
                from "analytics_companies__dbt_tmp20260916101749628487"
            );

        
    

    insert into "lake_catalog"."main_gold"."analytics_companies" ("company_id", "company_name", "domain", "cnpj", "owner_id", "created_at", "updated_at", "_loaded_at")
    (
        select "company_id", "company_name", "domain", "cnpj", "owner_id", "created_at", "updated_at", "_loaded_at"
        from "analytics_companies__dbt_tmp20260916101749628487"
    )
  