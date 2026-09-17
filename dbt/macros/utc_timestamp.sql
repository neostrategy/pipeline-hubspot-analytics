{#-
  Converte string ISO 8601 do HubSpot ("2026-08-27T15:20:55.888Z") em
  timestamp(6) sem fuso, em UTC.

  from_iso8601_timestamp devolve timestamp with time zone; o cast para
  timestamp(6) usa o fuso da sessao, que no Athena e sempre UTC.
  O try() evita que um valor malformado derrube o build inteiro.
-#}
{% macro utc_timestamp(coluna) -%}
    try(cast(from_iso8601_timestamp({{ coluna }}) as timestamp(6)))
{%- endmacro %}