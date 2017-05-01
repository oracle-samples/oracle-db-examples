set trims on
set long 10000000
set pagesize 10000
set linesize 250
set longchunksize 10000

var report clob;
exec :report := dbms_spm.evolve_sql_plan_baseline();
print :report

