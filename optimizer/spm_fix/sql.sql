select sql_id,plan_hash_value,sql_text from v$sql where sql_text like '%NO_ADAPTIVE_PLAN%'
/
