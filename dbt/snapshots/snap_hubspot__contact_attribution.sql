{#-
  Historico de atribuicao de campanha por contato.

  O HubSpot sobrescreve latest_source, campaign_* e utm_* a cada interacao.
  Sem este snapshot, um contato que entrou pela campanha A e voltou pela B
  aparece apenas como B — o primeiro toque se perde na fonte.

  Granularidade: a frequencia do pipeline. Duas conversoes no mesmo dia
  registram apenas o estado final.
-#}

{% snapshot snap_hubspot__contact_attribution %}

{{
    config(
        target_schema = 'samsung_hubspot_stg',
        unique_key = 'contact_id',
        strategy = 'check',
        check_cols = [
            'latest_source',
            'campaign_name',
            'campaign_type',
            'utm_source',
            'utm_medium',
            'utm_campaign'
        ],
        table_type = 'iceberg',
        tags = ['hubspot']
    )
}}

select
    contact_id,
    latest_source,
    latest_source_at,
    campaign_name,
    campaign_type,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_content,
    utm_term,
    original_source,
    updated_at
from {{ ref('stg_hubspot__contacts') }}

{% endsnapshot %}