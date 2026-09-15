
  
    
    

    create  table
      "lake_catalog"."main_gold"."assoc_deal_contact__dbt_tmp"
  
    as (
      

-- N:N deal <-> contato. is_primary alimenta o primary_contact_id do deal.
select
    from_id                                     as deal_id,
    to_id                                       as contact_id,
    assoc_type,
    coalesce(lower(assoc_type) like '%primary%', false) as is_primary,
    _loaded_at
from "lake_catalog"."main_staging"."stg_assoc__deals_contacts"
    );
  
  