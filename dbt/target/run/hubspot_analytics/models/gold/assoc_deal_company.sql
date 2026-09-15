
  
    
    

    create  table
      "lake_catalog"."main_gold"."assoc_deal_company__dbt_tmp"
  
    as (
      

select
    from_id     as deal_id,
    to_id       as company_id,
    assoc_type,
    _loaded_at
from "lake_catalog"."main_staging"."stg_assoc__deals_companies"
    );
  
  