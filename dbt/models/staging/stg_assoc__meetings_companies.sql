{{ config(materialized='view') }}
{{ stg_associacoes('meetings', 'companies') }}
