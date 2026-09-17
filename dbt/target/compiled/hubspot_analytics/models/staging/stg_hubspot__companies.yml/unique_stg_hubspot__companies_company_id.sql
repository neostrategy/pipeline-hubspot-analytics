
    
    

select
    company_id as unique_field,
    count(*) as n_records

from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__companies"
where company_id is not null
group by company_id
having count(*) > 1


