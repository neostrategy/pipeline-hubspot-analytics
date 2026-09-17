{#-
  Por padrao o dbt concatena o schema do target com o do modelo,
  produzindo nomes como "samsung_hubspot_stg_samsung_hubspot_mart".

  Aqui o +schema declarado no dbt_project.yml e usado literalmente,
  porque cada camada tem um database proprio no Glue.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}