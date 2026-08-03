{{ config(materialized='view') }}
{{ stg_associacoes('deals', 'contacts') }}
