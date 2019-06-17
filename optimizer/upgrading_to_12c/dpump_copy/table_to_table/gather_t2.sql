exec dbms_stats.delete_table_stats(ownname=>'s1',tabname=>'t2')
exec dbms_stats.gather_table_stats(ownname=>'s1',tabname=>'t2',method_opt=>'for all columns size auto');
