select sql_handle,sql_text,accepted,enabled,fixed from dba_sql_plan_baselines where sql_text like '%HELLO%';

select * from table(dbms_xplan.display_sql_plan_baseline(sql_handle=>'SQL_d836e5d3c42a4dbd')) ;
