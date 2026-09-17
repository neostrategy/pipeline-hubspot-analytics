
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select contact_id
from "awsdatacatalog"."samsung_hubspot_mart"."dim_contacts"
where contact_id is null



  
  
      
    ) dbt_internal_test