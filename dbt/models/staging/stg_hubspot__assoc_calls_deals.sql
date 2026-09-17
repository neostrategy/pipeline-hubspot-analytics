{{
    config(
        materialized = 'incremental',
        table_type = 'iceberg',
        unique_key = ['from_id', 'to_id'],
        incremental_strategy = 'merge',
        tags = ['hubspot']
    )
}}

{{ stg_associacoes('calls', 'deals') }}