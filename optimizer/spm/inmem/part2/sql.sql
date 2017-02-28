select sql_text,is_shareable,is_bind_aware,child_number,sql_plan_baseline from v$sql
where sql_text like '%SPM%';
