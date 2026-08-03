

select 'CALL' as engagement_type, from_id as activity_id, to_id as company_id, assoc_type, _loaded_at
from "analytics"."main_staging"."stg_assoc__calls_companies"
union all
select 'MEETING', from_id, to_id, assoc_type, _loaded_at
from "analytics"."main_staging"."stg_assoc__meetings_companies"