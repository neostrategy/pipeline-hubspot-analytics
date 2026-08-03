

-- Materializa o snapshot SCD2 no formato analítico:
-- 1 linha por período em que o deal ficou num estágio.
select
    deal_id,
    pipeline_id,
    stage_id,
    dbt_valid_from                                   as valid_from,
    dbt_valid_to                                     as valid_to,
    (dbt_valid_to is null)                           as is_current,
    round(
        date_diff('minute', dbt_valid_from,
                  coalesce(dbt_valid_to, now())) / 60.0, 2
    )                                                as duration_hours
from "analytics"."snapshots"."snap_deals_stage"