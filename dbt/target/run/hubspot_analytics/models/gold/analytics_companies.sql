
        
            delete from "analytics"."main_gold"."analytics_companies"
            where (
                company_id) in (
                select (company_id)
                from "analytics_companies__dbt_tmp20260802181835466252"
            );

        
    

    insert into "analytics"."main_gold"."analytics_companies" ("company_id", "company_name", "domain", "owner_id", "created_at", "updated_at", "_loaded_at")
    (
        select "company_id", "company_name", "domain", "owner_id", "created_at", "updated_at", "_loaded_at"
        from "analytics_companies__dbt_tmp20260802181835466252"
    )
  