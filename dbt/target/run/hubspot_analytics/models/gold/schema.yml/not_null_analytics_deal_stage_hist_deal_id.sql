
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select deal_id
from "lake_catalog"."main_gold"."analytics_deal_stage_hist"
where deal_id is null



  
  
      
    ) dbt_internal_test