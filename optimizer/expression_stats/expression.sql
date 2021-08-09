spool expression
--
-- Demonstrates the usefulness of expression statistics
-- Creates a table "T" - and note that session requires
-- read access to V$SESSION
--
set linesize 250
set trims on
set tab off
column plan_table_output format a100
column expression_text format a100
column table_name format a40
column owner format a40

var sqlid varchar2(20)

create table t as
select sysdate-50+rownum/100 delivery_date,1 control_flag,
       rownum account_id
from   dual connect by rownum<=10000;

SELECT /* MYQUERY */ COUNT(*)
FROM t
WHERE ( "DELIVERY_DATE" >= trunc(sysdate@!, 'fmyear')
   AND ( coalesce("CONTROL_FLAG", 1) = 1
   OR coalesce("CONTROL_FLAG", 1) = 3 )
   AND ( coalesce(substr(to_char("ACCOUNT_ID"), 4, 1), '1') = '1'
   OR coalesce(substr(to_char("ACCOUNT_ID"), 4, 1), '1') = '3' )
   AND "DELIVERY_DATE" <= trunc(sysdate@! - 1) );

exec select prev_sql_id into :sqlid from v$session where sid=sys_context('userenv','sid');

SELECT /* MYQUERY */ COUNT(*)
FROM t
WHERE ( "DELIVERY_DATE" >= trunc(sysdate@!, 'fmyear')
   AND ( coalesce("CONTROL_FLAG", 1) = 1
   OR coalesce("CONTROL_FLAG", 1) = 3 )
   AND ( coalesce(substr(to_char("ACCOUNT_ID"), 4, 1), '1') = '1'
   OR coalesce(substr(to_char("ACCOUNT_ID"), 4, 1), '1') = '3' )
   AND "DELIVERY_DATE" <= trunc(sysdate@! - 1) );

--
-- Note the poor cardinality estimate of "2"
--
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR());

select distinct table_name,owner,expression_text 
from   dba_expression_statistics 
where  (table_name,owner) 
    in (select object_name, object_owner 
        from v$sql_plan 
        where object_type = 'TABLE' 
        and sql_id = :sqlid);
--
-- Create the expression statistics
--
select dbms_stats.create_extended_stats(USER,'T',
       q'[(COALESCE("CONTROL_FLAG",1))]')
from dual;

select dbms_stats.create_extended_stats(USER,'T',
       q'[(COALESCE(SUBSTR(TO_CHAR("ACCOUNT_ID"),4,1),'1'))]') 
from dual;

begin
  dbms_stats.gather_table_stats(USER,'T', 
    method_opt=>q'[for columns (COALESCE("CONTROL_FLAG",1))]', 
    no_invalidate=>FALSE);

   dbms_stats.gather_table_stats(USER,'T',
    method_opt=>q'[for columns (COALESCE(SUBSTR(TO_CHAR("ACCOUNT_ID"),4,1),'1'))]',
    no_invalidate=>FALSE);
end;
/

SELECT /* MYQUERY */ COUNT(*)
FROM t
WHERE ( "DELIVERY_DATE" >= trunc(sysdate@!, 'fmyear')
   AND ( coalesce("CONTROL_FLAG", 1) = 1
   OR coalesce("CONTROL_FLAG", 1) = 3 )
   AND ( coalesce(substr(to_char("ACCOUNT_ID"), 4, 1), '1') = '1'
   OR coalesce(substr(to_char("ACCOUNT_ID"), 4, 1), '1') = '3' )
   AND "DELIVERY_DATE" <= trunc(sysdate@! - 1) );

--
-- Note the improved cardinality estimate
--
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR());

spool off
