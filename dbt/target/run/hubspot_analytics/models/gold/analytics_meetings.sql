
        
            delete from "analytics"."main_gold"."analytics_meetings"
            where (
                meeting_id) in (
                select (meeting_id)
                from "analytics_meetings__dbt_tmp20260802181835721145"
            );

        
    

    insert into "analytics"."main_gold"."analytics_meetings" ("meeting_id", "owner_id", "title", "outcome", "location", "starts_at", "ends_at", "occurred_at", "created_at", "updated_at", "_loaded_at")
    (
        select "meeting_id", "owner_id", "title", "outcome", "location", "starts_at", "ends_at", "occurred_at", "created_at", "updated_at", "_loaded_at"
        from "analytics_meetings__dbt_tmp20260802181835721145"
    )
  