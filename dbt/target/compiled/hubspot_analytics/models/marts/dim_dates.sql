

/*
    Calendario. Uma linha por dia, de 2020 a 2035.

    Dimensao transversal: serve todos os projetos do cliente. Junta-se a
    qualquer fato pela coluna de data (created_date, occurred_date...).

    Nao depende de nenhuma fonte — e gerada. Reconstruir e barato e nao
    perde nada.
*/

with dias as (

    select
        cast(dia as date) as date_day
    from unnest(
        sequence(date '2020-01-01', date '2035-12-31', interval '1' day)
    ) as t(dia)

)

select
    date_day,

    -- partes da data
    year(date_day)                              as year_number,
    month(date_day)                             as month_number,
    day(date_day)                               as day_number,
    quarter(date_day)                           as quarter_number,
    day_of_week(date_day)                       as weekday_number,

    -- rotulos prontos para o BI
    date_format(date_day, '%Y-%m')              as year_month,
    date_format(date_day, '%Y')                 || '-Q'
        || cast(quarter(date_day) as varchar)   as year_quarter,
    format_datetime(date_day, 'xxxx-''W''ww')   as year_week,

    -- semana ISO: segunda a domingo
    date_trunc('week', date_day)                as week_start_date,
    date_add('day', 6, date_trunc('week', date_day))
                                                as week_end_date,
    date_trunc('month', date_day)               as month_start_date,
    last_day_of_month(date_day)                 as month_end_date,

    -- sinalizadores
    day_of_week(date_day) in (6, 7)             as is_weekend,
    day_of_week(date_day) not in (6, 7)         as is_weekday,
    date_day = last_day_of_month(date_day)      as is_month_end,

    -- posicao relativa, util para filtros de periodo no BI
    date_diff('day', current_date, date_day)    as days_from_today

from dias