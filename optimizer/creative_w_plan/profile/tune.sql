var task_name varchar2(30)

EXEC :task_name := dbms_sqltune.create_tuning_task(sql_id=>'g6y6gpnzww95b');

set echo on
EXEC dbms_sqltune.execute_tuning_task(:task_name);

select :task_name from dual;
