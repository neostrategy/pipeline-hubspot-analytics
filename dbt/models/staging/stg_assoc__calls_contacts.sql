{{ config(materialized='view') }}
{{ stg_associacoes('calls', 'contacts') }}
