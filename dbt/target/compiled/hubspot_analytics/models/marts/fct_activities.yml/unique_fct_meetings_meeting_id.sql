
    
    

select
    meeting_id as unique_field,
    count(*) as n_records

from "awsdatacatalog"."samsung_hubspot_mart"."fct_meetings"
where meeting_id is not null
group by meeting_id
having count(*) > 1


