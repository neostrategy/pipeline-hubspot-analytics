
    
    

select
    contact_id as unique_field,
    count(*) as n_records

from "lake_catalog"."main_gold"."analytics_contacts"
where contact_id is not null
group by contact_id
having count(*) > 1


