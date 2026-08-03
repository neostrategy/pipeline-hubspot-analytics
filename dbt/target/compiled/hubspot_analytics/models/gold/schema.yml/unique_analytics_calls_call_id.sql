
    
    

select
    call_id as unique_field,
    count(*) as n_records

from "analytics"."main_gold"."analytics_calls"
where call_id is not null
group by call_id
having count(*) > 1


