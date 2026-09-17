{{
    config(
        materialized = 'incremental',
        table_type = 'iceberg',
        unique_key = 'deal_id',
        incremental_strategy = 'merge',
        tags = ['hubspot']
    )
}}

select
    deal_id,
    deal_name,
    description,
    owner_id,

    pipeline_id,
    deal_stage,
    deal_type,
    forecast_category,
    stage_probability_ratio,
    next_step,

    deal_amount,
    closed_amount,
    projected_amount,

    product_category_interest,
    no_bo,
    direcionado,
    qualificado_para_qual_funil,

    closed_at,
    created_at,
    updated_at,
    _loaded_at

from {{ ref('stg_hubspot__deals') }}

{% if is_incremental() %}
where updated_at > (
    select coalesce(max(updated_at), timestamp '1970-01-01')
    from {{ this }}
)
{% endif %}