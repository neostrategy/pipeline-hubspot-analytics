{{
    config(
        materialized = 'table',
        table_type = 'iceberg',
        tags = ['hubspot']
    )
}}

/*
    Chamadas e reunioes unificadas, atribuidas a contato, negocio e empresa.

    Grao: uma linha por atividade (activity_id + engagement_type).
    Uma atividade pode ter varios contatos ou negocios associados; aqui
    escolhemos o menor id para preservar o grao. A relacao completa vive
    nos modelos de staging de associacao.
*/

with atividades as (

    select
        call_id                                 as activity_id,
        'CALL'                                  as engagement_type,
        owner_id,
        call_title                              as title,
        occurred_at,
        call_disposition                        as outcome,
        call_duration_ms                        as duration_ms,
        cast(null as timestamp(6))              as started_at,
        cast(null as timestamp(6))              as ended_at,
        _loaded_at
    from {{ ref('stg_hubspot__calls') }}

    union all

    select
        meeting_id,
        'MEETING',
        owner_id,
        meeting_title,
        occurred_at,
        meeting_outcome,
        cast(null as bigint),
        started_at,
        ended_at,
        _loaded_at
    from {{ ref('stg_hubspot__meetings') }}

),

contato as (
    select activity_id, engagement_type, min(contact_id) as contact_id
    from {{ ref('int_activity_contact') }}
    group by 1, 2
),

negocio as (
    select activity_id, engagement_type, min(deal_id) as deal_id
    from {{ ref('int_activity_deal') }}
    group by 1, 2
),

empresa as (
    select activity_id, engagement_type, min(company_id) as company_id
    from {{ ref('int_activity_company') }}
    group by 1, 2
),

-- empresa herdada do negocio quando a atividade nao tem associacao direta
empresa_do_negocio as (
    select from_id as deal_id, min(to_id) as company_id
    from {{ ref('stg_hubspot__assoc_deals_companies') }}
    group by 1
)

select
    a.activity_id,
    a.engagement_type,
    c.contact_id,
    n.deal_id,
    coalesce(e.company_id, ed.company_id)       as company_id,
    a.owner_id,
    a.title,

    a.occurred_at,
    cast(a.occurred_at as date)                 as occurred_date,
    a.outcome,
    a.duration_ms,
    cast(round(a.duration_ms / 60000.0, 2) as decimal(12,2))     as duration_minutes,
    a.started_at,
    a.ended_at,

    e.company_id is null
        and ed.company_id is not null           as is_company_inherited_from_deal,
    -- atividade de qualificacao: contato associado, negocio ainda nao
    n.deal_id is null
        and c.contact_id is not null            as is_qualification_activity,

    a._loaded_at

from atividades a
left join contato c
       on a.activity_id = c.activity_id
      and a.engagement_type = c.engagement_type
left join negocio n
       on a.activity_id = n.activity_id
      and a.engagement_type = n.engagement_type
left join empresa e
       on a.activity_id = e.activity_id
      and a.engagement_type = e.engagement_type
left join empresa_do_negocio ed
       on n.deal_id = ed.deal_id