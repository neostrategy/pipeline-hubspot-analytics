{{
    config(
        materialized = 'table',
        table_type = 'iceberg',
        tags = ['hubspot']
    )
}}

/*
    Um registro por toque de campanha de cada contato.

    Um "toque" e uma versao distinta da atribuicao capturada pelo snapshot:
    sempre que latest_source, campaign_* ou utm_* mudam, nasce um toque novo.

    touch_number = 1  -> entrada do contato
    touch_number > 1  -> retorno, possivelmente por outra campanha
*/

with versoes as (

    select
        contact_id,
        latest_source,
        campaign_name,
        campaign_type,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content,
        utm_term,
        original_source,
        cast(dbt_valid_from as timestamp(6))    as touch_started_at,
        cast(dbt_valid_to   as timestamp(6))    as touch_ended_at
    from {{ ref('snap_hubspot__contact_attribution') }}

),

numeradas as (

    select
        *,
        row_number() over (
            partition by contact_id
            order by touch_started_at
        )                                       as touch_number,
        lag(campaign_name) over (
            partition by contact_id
            order by touch_started_at
        )                                       as previous_campaign_name
    from versoes

)

select
    contact_id,
    touch_number,
    campaign_name,
    campaign_type,
    previous_campaign_name,
    latest_source,
    original_source,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    touch_started_at,
    touch_ended_at,
    touch_ended_at is null                      as is_current_touch,
    touch_number = 1                            as is_first_touch,
    touch_number > 1
        and previous_campaign_name is not null
        and campaign_name is not null
        and campaign_name <> previous_campaign_name
                                                as is_campaign_switch
from numeradas