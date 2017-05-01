@base

Pause Press <CR> to continue...

var sh varchar2(200)
var pn varchar2(200)

begin
   SELECT sql_handle,plan_name
   INTO   :sh,:pn
   FROM   dba_sql_plan_baselines
   WHERE  sql_text LIKE '%PROFTEST%'
   AND    accepted = 'YES';
end;
/

SELECT *
FROM   TABLE(
         DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE(:sh,:pn,'basic')
       ) t
/

