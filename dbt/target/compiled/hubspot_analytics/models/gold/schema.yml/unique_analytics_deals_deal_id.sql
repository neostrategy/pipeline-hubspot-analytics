
    
    

select
    deal_id as unique_field,
    count(*) as n_records

from "lake_catalog"."main_gold"."analytics_deals"
where deal_id is not null
group by deal_id
having count(*) > 1


