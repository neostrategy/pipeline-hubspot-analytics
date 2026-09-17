
    
    

select
    date_day as unique_field,
    count(*) as n_records

from "awsdatacatalog"."shared_core_mart"."dim_dates"
where date_day is not null
group by date_day
having count(*) > 1


