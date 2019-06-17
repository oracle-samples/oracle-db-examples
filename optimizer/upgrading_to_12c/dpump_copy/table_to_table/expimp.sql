exec dbms_stats.drop_stat_table('s1','my_stat_tab')
exec dbms_stats.create_stat_table('s1','my_stat_tab')

exec dbms_stats.export_table_stats('s1','t1',stattab=>'my_stat_tab')
exec dbms_stats.export_index_stats('s1','t1i',stattab=>'my_stat_tab')

exec dbms_stats.import_table_stats('s1','t2',stattab=>'my_stat_tab')
exec dbms_stats.import_index_stats('s1','t2i',stattab=>'my_stat_tab')


