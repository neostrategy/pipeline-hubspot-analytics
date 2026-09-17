
        
            delete from "lake_catalog"."main_gold"."analytics_meetings"
            where (
                meeting_id) in (
                select (meeting_id)
                from "analytics_meetings__dbt_tmp20260916101800663960"
            );

        
    

    insert into "lake_catalog"."main_gold"."analytics_meetings" ("meeting_id", "owner_id", "title", "outcome", "location", "starts_at", "ends_at", "occurred_at", "created_at", "updated_at", "_loaded_at")
    (
        select "meeting_id", "owner_id", "title", "outcome", "location", "starts_at", "ends_at", "occurred_at", "created_at", "updated_at", "_loaded_at"
        from "analytics_meetings__dbt_tmp20260916101800663960"
    )
  