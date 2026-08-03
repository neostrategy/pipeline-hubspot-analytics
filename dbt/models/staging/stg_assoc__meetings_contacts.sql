{{ config(materialized='view') }}
{{ stg_associacoes('meetings', 'contacts') }}
