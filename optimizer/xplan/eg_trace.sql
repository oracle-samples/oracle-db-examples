--
-- Generate an example trace file
--
alter system flush shared_pool;
alter session set tracefile_identifier = 'EXAMPLE_TRACE';
alter session set events = '10053 trace name context forever, level 1';
select 
  /*+
      BEGIN_OUTLINE_DATA
      IGNORE_OPTIM_EMBEDDED_HINTS
      OPTIMIZER_FEATURES_ENABLE('12.2.0.1')
      DB_VERSION('12.2.0.1')
      ALL_ROWS
      OUTLINE_LEAF(@"SEL$58A6D7F6")
      MERGE(@"SEL$1" >"SEL$2")
      OUTLINE(@"SEL$2")
      OUTLINE(@"SEL$1")
      FULL(@"SEL$58A6D7F6" "E"@"SEL$1")
      INDEX_RS_ASC(@"SEL$58A6D7F6" "T"@"SEL$1" ("TASKS"."EMP_ID"))
      LEADING(@"SEL$58A6D7F6" "E"@"SEL$1" "T"@"SEL$1")
      USE_NL(@"SEL$58A6D7F6" "T"@"SEL$1")
      END_OUTLINE_DATA
  */
       e.ename as "Employee Name",
       t.tname as "Task Name"
from   employees        e
       join tasks t on (t.emp_id = e.id)
where  e.etype <= 5;

alter session set events = '10053 trace name context off';

@@adv
