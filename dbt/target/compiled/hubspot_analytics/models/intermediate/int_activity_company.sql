

/*
    Associacoes de atividade (call ou meeting) com company.
    Unifica as duas origens sob o mesmo grao de fct_activities.
*/

select
    from_id         as activity_id,
    'CALL'          as engagement_type,
    to_id           as company_id
from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__assoc_calls_companies"

union all

select
    from_id,
    'MEETING',
    to_id
from "awsdatacatalog"."samsung_hubspot_stg"."stg_hubspot__assoc_meetings_companies"