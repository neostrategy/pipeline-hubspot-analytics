
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select mes_entrada
from "analytics"."main_gold"."mart_entradas"
where mes_entrada is null



  
  
      
    ) dbt_internal_test