
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        engagement_type as value_field,
        count(*) as n_records

    from "lake_catalog"."main_gold"."fct_activities"
    group by engagement_type

)

select *
from all_values
where value_field not in (
    'CALL','MEETING'
)



  
  
      
    ) dbt_internal_test