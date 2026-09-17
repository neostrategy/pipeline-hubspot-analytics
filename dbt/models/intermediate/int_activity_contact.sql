{{ config(materialized='ephemeral', tags=['hubspot']) }}

/*
    Associacoes de atividade (call ou meeting) com contact.
    Unifica as duas origens sob o mesmo grao de fct_activities.
*/

select
    from_id         as activity_id,
    'CALL'          as engagement_type,
    to_id           as contact_id
from {{ ref('stg_hubspot__assoc_calls_contacts') }}

union all

select
    from_id,
    'MEETING',
    to_id
from {{ ref('stg_hubspot__assoc_meetings_contacts') }}