
        
            delete from "lake_catalog"."main_gold"."analytics_calls"
            where (
                call_id) in (
                select (call_id)
                from "analytics_calls__dbt_tmp20260916101741059687"
            );

        
    

    insert into "lake_catalog"."main_gold"."analytics_calls" ("call_id", "owner_id", "title", "direction", "disposition", "status", "duration_ms", "occurred_at", "created_at", "updated_at", "_loaded_at")
    (
        select "call_id", "owner_id", "title", "direction", "disposition", "status", "duration_ms", "occurred_at", "created_at", "updated_at", "_loaded_at"
        from "analytics_calls__dbt_tmp20260916101741059687"
    )
  