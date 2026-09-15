
    
    

select
    meeting_id as unique_field,
    count(*) as n_records

from "lake_catalog"."main_gold"."analytics_meetings"
where meeting_id is not null
group by meeting_id
having count(*) > 1


