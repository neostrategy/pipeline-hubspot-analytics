
    
    

with all_values as (

    select
        engagement_type as value_field,
        count(*) as n_records

    from "analytics"."main_gold"."fct_activities"
    group by engagement_type

)

select *
from all_values
where value_field not in (
    'CALL','MEETING'
)


