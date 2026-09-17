
    
    

select
    contact_id as unique_field,
    count(*) as n_records

from "awsdatacatalog"."samsung_hubspot_mart"."dim_contacts"
where contact_id is not null
group by contact_id
having count(*) > 1


