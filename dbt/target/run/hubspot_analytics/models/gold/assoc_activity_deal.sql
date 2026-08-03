
  
    
    

    create  table
      "analytics"."main_gold"."assoc_activity_deal__dbt_tmp"
  
    as (
      

select 'CALL' as engagement_type, from_id as activity_id, to_id as deal_id, assoc_type, _loaded_at
from "analytics"."main_staging"."stg_assoc__calls_deals"
union all
select 'MEETING', from_id, to_id, assoc_type, _loaded_at
from "analytics"."main_staging"."stg_assoc__meetings_deals"
    );
  
  