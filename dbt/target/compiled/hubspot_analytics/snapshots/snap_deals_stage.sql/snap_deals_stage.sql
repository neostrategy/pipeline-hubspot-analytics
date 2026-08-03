



-- SCD2 do estágio do deal: cada mudança de dealstage gera uma nova
-- versão com dbt_valid_from/dbt_valid_to. Base do analytics_deal_stage_hist.
select
    deal_id,
    pipeline_id,
    stage_id
from "analytics"."main_staging"."stg_hubspot__deals"
