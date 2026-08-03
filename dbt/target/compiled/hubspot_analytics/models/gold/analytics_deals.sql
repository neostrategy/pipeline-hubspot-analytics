

with principal as (
    select deal_id, min(contact_id) as primary_contact_id
    from "analytics"."main_gold"."assoc_deal_contact"
    where is_primary
    group by 1
),

qualquer_contato as (
    select deal_id, min(contact_id) as contact_id
    from "analytics"."main_gold"."assoc_deal_contact"
    group by 1
),

empresa as (
    select deal_id, min(company_id) as company_id
    from "analytics"."main_gold"."assoc_deal_company"
    group by 1
)

select
    d.deal_id,
    deal_name,
    pipeline_id,
    stage_id,
    amount,
    owner_id,
    deal_type,
    created_at,
    updated_at,
    close_date,
    coalesce(p.primary_contact_id, q.contact_id) as primary_contact_id,
    e.company_id,
    -- deriváveis do estágio; ajustar aos ids reais dos estágios de
    -- fechamento do pipeline de vocês (API de pipelines resolve labels)
    coalesce(stage_id ilike '%closedwon%', false)   as is_won,
    coalesce(stage_id ilike '%closed%', false)      as is_closed,
    _loaded_at
from "analytics"."main_staging"."stg_hubspot__deals" d
left join principal p on d.deal_id = p.deal_id
left join qualquer_contato q on d.deal_id = q.deal_id
left join empresa e on d.deal_id = e.deal_id


where updated_at > (select coalesce(max(updated_at), timestamp '1970-01-01') from "analytics"."main_gold"."analytics_deals")
