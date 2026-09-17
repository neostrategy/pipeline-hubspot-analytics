{#-
  Historico de etapa dos negocios.

  O HubSpot sobrescreve dealstage a cada avanco. Sem este snapshot nao ha
  como responder quanto tempo um negocio ficou em cada etapa.
-#}

{% snapshot snap_hubspot__deal_stage %}

{{
    config(
        target_schema = 'samsung_hubspot_stg',
        unique_key = 'deal_id',
        strategy = 'check',
        check_cols = ['deal_stage'],
        table_type = 'iceberg',
        tags = ['hubspot']
    )
}}

select
    deal_id,
    pipeline_id,
    deal_stage,
    deal_amount,
    owner_id,
    updated_at
from {{ ref('stg_hubspot__deals') }}

{% endsnapshot %}