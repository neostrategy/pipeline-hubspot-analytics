
  
  create view "lake_catalog"."main_staging"."stg_hubspot__companies__dbt_tmp" as (
    

with raw as (

    select *
    from read_json_auto(
        'data/raw/hubspot/companies/*.jsonl',
        union_by_name = true
    )

),

dedup as (

    select *,
           row_number() over (partition by id order by load_ts desc) as _rn
    from raw

)

select
    cast(id as bigint)                          as company_id,
    name                                        as company_name,
    domain,
    nullif(regexp_replace(cast(cnpj as varchar), '[^0-9A-Za-z]', '', 'g'), '')
                                                as cnpj,
    cast(cnpj as varchar)                       as cnpj_original,
    (length(nullif(regexp_replace(cast(cnpj as varchar), '[^0-9A-Za-z]', '', 'g'), '')) = 14) as cnpj_valido,
    try_cast(hubspot_owner_id as bigint)        as owner_id,
    try_cast(createdate as timestamp)           as created_at,
    try_cast(hs_lastmodifieddate as timestamp)  as updated_at,
    try_cast(load_ts as timestamp)              as _loaded_at
from dedup
where _rn = 1
  );
