
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    deal_id as unique_field,
    count(*) as n_records

from "awsdatacatalog"."samsung_hubspot_mart"."dim_deals"
where deal_id is not null
group by deal_id
having count(*) > 1



  
  
      
    ) dbt_internal_test