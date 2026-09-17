
    
    

select
    contact_id as unique_field,
    count(*) as n_records

from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__contacts"
where contact_id is not null
group by contact_id
having count(*) > 1


