set pagesize 100
column sql_text format a80
set linesize 200
set trims on
set pagesize 100
column sql_profile format a30
column exact_matching_signature format 99999999999999999999999

select sql_id,exact_matching_signature,plan_hash_value,sql_text 
from v$sql
where sql_text = 'select /* SPMTEST */ /*+ INDEX(sales salesi) */ * from sales WHERE sale_date >= trunc(sysdate)'
/

var phv number

begin
  select plan_hash_value
  into   :phv
  from   v$sql
  where  sql_text = 'select /* SPMTEST */ /*+ INDEX(sales salesi) */ * from sales WHERE sale_date >= trunc(sysdate)';
end;
/
