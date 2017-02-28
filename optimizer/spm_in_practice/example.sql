set echo on
spool example

alter system flush shared_pool;

@user

PROMPT
PROMPT **** It is easy to drop SQL plan baselines for a specific schema...
PROMPT
@util/dropu SPMTEST
@table
@q1

PROMPT **** Capture our query

@load

PROMPT **** Display the SQL Plan Baselines

@util/listu SPMTEST

PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** Display the plan for our SQL plan baseline

var handle varchar2(50)
begin
  select sql_handle into :handle from dba_sql_plan_baselines where parsing_schema_name = 'SPMTEST';
end;
/

SELECT *
FROM   TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE(:handle,NULL)) t;

PROMPT **** Note that the index is used in the exeution plan
PROMPT
PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** Execute the query again and confirm that it is using the SQL plan baseline

@q1
@util/plan

PROMPT **** Note (above) that the SQL plan baseline is being used
PROMPT
PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** We do not expect to see non-matching SQL execution plans...

@util/nomatchu SPMTEST

PROMPT **** Query above returns no rows because all out queries
PROMPT **** with SQL plan baselines are using them
PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** Drop the index

DROP INDEX tabi;

PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** Execute the query again and confirm that it is NOT using the baselines
PROMPT      because the plan cannot be used - the index has gone

@q1
@q1
@util/plan

PROMPT **** Note (above) that the SQL plan baseline is NOT being used
PROMPT **** because the index has gone.
PROMPT **** Press <CR> to continue...
PAUSE

var planname varchar2(100)
begin
  select plan_name into :planname from dba_sql_plan_baselines where parsing_schema_name = 'SPMTEST' and accepted = 'YES';
end;
/

column hint format a100
SELECT  extractValue(value(h),'.') AS hint
FROM    sys.sqlobj$plan od,
        TABLE(xmlsequence(
          extract(xmltype(od.other_xml),'/*/outline_data/hint'))) h
WHERE od.other_xml is not null
AND   (signature,category,obj_type,plan_id) = (select signature,
                             category,
                             obj_type,
                             plan_id
                      from   sys.sqlobj$ so
                       where so.name = :planname);

PROMPT **** Above - the SQL plan baseline outline hints include an INDEX hint for the index we dropped.
PROMPT **** The query is no longer able to obey this hint.
PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** We now expect to find our problem query...
@util/nomatchu SPMTEST

PROMPT **** Above, we can see that a SQL statement with a SQL plan baseline
PROMPT **** is not using the SQL plan baseline. In this case, it's because
PROMPT **** we dropped the index so the accepted SQL plan baseline cannot be used.
PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** We have captured a new plan in SQL plan history...
@util/listu SPMTEST
PROMPT **** Above, there are now two SQL plan history entries for our query. The new plan has not been accepted yet.
PROMPT **** We can choose to evolve it if we wish and then the query will be under the control of SPM.
PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** The query will show up as a candidate for evolution
@util/evou SPMTEST
PROMPT **** Above, we have identified a SQL plan history entry that is a candidate for evolving.
PROMPT **** Press <CR> to continue...
PAUSE

PROMPT **** Evolve our SQL plan history entry...
DECLARE
  ret CLOB;
BEGIN
  ret := DBMS_SPM.EVOLVE_SQL_PLAN_BASELINE(sql_handle=>:handle, verify=>'NO');
END;
/
PROMPT **** Press <CR> to continue...
PAUSE

@util/evou SPMTEST
PROMPT **** Above, there are no longer candidates for evolving.
PROMPT **** Press <CR> to continue...
PAUSE

@util/listu SPMTEST
PROMPT **** Above, all out SQL plan baselines are accepted
PROMPT **** Press <CR> to continue...
PAUSE

@q1
@q1
@q1
@util/plan

PROMPT **** Above, our query is using a SQL plan baseline again.
PROMPT **** It's a full table scan this time because there is no index.
PROMPT **** Press <CR> to continue...
PAUSE

@util/nomatchu SPMTEST

PROMPT **** Now all the queries with SQL plan baselines are matching
PROMPT **** successfully, so the above query returns no rows.
PROMPT **** Press <CR> to continue...
PAUSE

spool off
