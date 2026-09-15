
  
    
    

    create  table
      "lake_catalog"."main_gold"."fct_activities__dbt_tmp"
  
    as (
      

-- Calls + meetings unificados e atribuídos a contato, negócio e empresa.
-- Grão: 1 linha por atividade (activity_id + engagement_type).
-- Uma atividade pode ter vários contatos/deals associados; escolhemos o
-- menor id para manter o grão — a relação completa vive nas assoc_*.

with atividades as (

    select
        call_id                     as activity_id,
        'CALL'                      as engagement_type,
        owner_id,
        title,
        occurred_at,
        cast(disposition as varchar) as outcome,
        duration_ms,
        cast(null as timestamp)     as starts_at,
        cast(null as timestamp)     as ends_at,
        _loaded_at
    from "lake_catalog"."main_gold"."analytics_calls"

    union all

    select
        meeting_id,
        'MEETING',
        owner_id,
        title,
        occurred_at,
        cast(outcome as varchar),
        cast(null as integer),
        starts_at,
        ends_at,
        _loaded_at
    from "lake_catalog"."main_gold"."analytics_meetings"

),

contato as (
    select activity_id, engagement_type, min(contact_id) as contact_id
    from "lake_catalog"."main_gold"."assoc_activity_contact"
    group by 1, 2
),

negocio as (
    select activity_id, engagement_type, min(deal_id) as deal_id
    from "lake_catalog"."main_gold"."assoc_activity_deal"
    group by 1, 2
),

empresa as (
    select activity_id, engagement_type, min(company_id) as company_id
    from "lake_catalog"."main_gold"."assoc_activity_company"
    group by 1, 2
),

-- empresa herdada do deal quando a atividade não tem associação direta
empresa_do_deal as (
    select deal_id, min(company_id) as company_id
    from "lake_catalog"."main_gold"."assoc_deal_company"
    group by 1
)

select
    a.activity_id,
    a.engagement_type,
    c.contact_id,
    n.deal_id,
    coalesce(e.company_id, ed.company_id)       as company_id,
    (e.company_id is null and ed.company_id is not null) as empresa_herdada_do_deal,
    a.owner_id,
    a.title,
    a.occurred_at,
    cast(a.occurred_at as date)                 as occurred_data,
    a.outcome,
    a.duration_ms,
    round(a.duration_ms / 60000.0, 2)           as duracao_min,
    a.starts_at,
    a.ends_at,
    -- atividade de qualificação: contato sem negócio associado
    (n.deal_id is null and c.contact_id is not null) as sem_negocio,
    a._loaded_at
from atividades a
left join contato c
       on a.activity_id = c.activity_id and a.engagement_type = c.engagement_type
left join negocio n
       on a.activity_id = n.activity_id and a.engagement_type = n.engagement_type
left join empresa e
       on a.activity_id = e.activity_id and a.engagement_type = e.engagement_type
left join empresa_do_deal ed
       on n.deal_id = ed.deal_id
    );
  
  