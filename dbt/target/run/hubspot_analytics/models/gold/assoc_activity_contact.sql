
  
    
    

    create  table
      "analytics"."main_gold"."assoc_activity_contact__dbt_tmp"
  
    as (
      

select 'CALL' as engagement_type, from_id as activity_id, to_id as contact_id, assoc_type, _loaded_at
from "analytics"."main_staging"."stg_assoc__calls_contacts"
union all
select 'MEETING', from_id, to_id, assoc_type, _loaded_at
from "analytics"."main_staging"."stg_assoc__meetings_contacts"
    );
  
  