
    
    

select
    company_id as unique_field,
    count(*) as n_records

from "analytics"."main_gold"."analytics_companies"
where company_id is not null
group by company_id
having count(*) > 1


