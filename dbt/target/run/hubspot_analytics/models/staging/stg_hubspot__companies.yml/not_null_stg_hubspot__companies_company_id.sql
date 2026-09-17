
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select company_id
from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__companies"
where company_id is null



  
  
      
    ) dbt_internal_test