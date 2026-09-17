
    
    

select
    call_id as unique_field,
    count(*) as n_records

from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__calls"
where call_id is not null
group by call_id
having count(*) > 1


