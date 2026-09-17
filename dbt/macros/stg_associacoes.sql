{#-
  Gera o staging de uma tabela de associacao do HubSpot.

  Cada par (from_id, to_id) fica com a carga mais recente. O filtro
  incremental le apenas as particoes gravadas desde a ultima execucao.
-#}
{% macro stg_associacoes(from_object, to_object) %}

with raw as (

    select *
    from {{ source('hubspot_raw', 'assoc_' ~ from_object ~ '_' ~ to_object) }}

    {% if is_incremental() %}
    where dt >= (
        select coalesce(max(date_format(_loaded_at, '%Y-%m-%d')), '1900-01-01')
        from {{ this }}
    )
    {% endif %}

),

dedup as (

    select *,
           row_number() over (
               partition by from_id, to_id
               order by load_ts desc
           ) as _rn
    from raw

)

select
    cast(from_id as bigint)             as from_id,
    cast(to_id as bigint)               as to_id,
    type                                as assoc_type,
    {{ utc_timestamp('load_ts') }}      as _loaded_at
from dedup
where _rn = 1

{% endmacro %}