{{ config(materialized='view') }}
{{ stg_associacoes('calls', 'companies') }}
