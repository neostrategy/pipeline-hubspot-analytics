

-- Mapa de entradas: quem entrou no CRM, quando e por qual origem.
-- Projeção do hub (analytics_contacts) no formato que o BI consome:
-- 1 linha por contato, com granularidade de data pronta para coorte.

with contatos as (

    select * from "lake_catalog"."main_gold"."analytics_contacts"

),

importacoes as (

    -- Importação em lote cria muitos contatos no mesmo minuto, o que
    -- gera um pico artificial na coorte. Detectamos pelo volume por
    -- minuto de criação para o BI poder filtrar.
    select date_trunc('minute', created_at) as minuto_criacao
    from contatos
    group by 1
    having count(*) >= 20

)

select
    c.contact_id,
    c.email,
    coalesce(c.first_name, '') || ' ' || coalesce(c.last_name, '') as nome,
    c.owner_id,
    c.lifecycle_stage,

    -- quando entrou
    c.created_at                                as entrada_em,
    cast(c.created_at as date)                  as entrada_data,
    strftime(c.created_at, '%Y-%m')             as mes_entrada,
    strftime(c.created_at, '%G-W%V')            as semana_entrada,

    -- de onde veio (first-touch)
    coalesce(c.original_source, c.origem_analytics, 'DESCONHECIDA') as origem,
    c.origem_detalhe_1                          as origem_detalhe,
    c.origem_detalhe_2                          as origem_detalhe_2,
    c.primeira_url                              as primeira_url,

    -- last-touch (o que trouxe de volta)
    c.latest_source                             as origem_recente,
    c.latest_source_at                          as origem_recente_em,

    -- campanha (utm_* dependem de propriedade custom no portal)
    c.utm_source,
    c.utm_medium,
    c.utm_campaign,
    c.utm_content,
    c.utm_term,
    coalesce(
        c.utm_campaign,
        c.origem_detalhe_1
    )                                           as campanha,

    -- rastreio de mídia paga
    (c.gclid is not null and c.gclid <> '')     as veio_google_ads,
    (c.fbclid is not null and c.fbclid <> '')   as veio_meta_ads,

    -- como o registro nasceu (formulário, importação, integração...)
    c.criacao_origem_label                      as criacao_origem,

    -- ruído de coorte: importações em lote
    (i.minuto_criacao is not null
     or upper(coalesce(c.original_source, '')) = 'OFFLINE')
                                                as is_importacao,

    c._loaded_at

from contatos c
left join importacoes i
       on date_trunc('minute', c.created_at) = i.minuto_criacao