{{ config(materialized='view') }}
{{ stg_associacoes('calls', 'deals') }}
