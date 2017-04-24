SET linesize 180
SET longchunksize 180
SET pagesize 900
SET long 1000000
SELECT dbms_sqltune.report_tuning_task(:task_name) FROM dual;
