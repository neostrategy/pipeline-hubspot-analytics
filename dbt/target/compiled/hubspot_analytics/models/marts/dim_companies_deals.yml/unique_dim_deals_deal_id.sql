
    
    

select
    deal_id as unique_field,
    count(*) as n_records

from "awsdatacatalog"."samsung_hubspot_mart"."dim_deals"
where deal_id is not null
group by deal_id
having count(*) > 1


