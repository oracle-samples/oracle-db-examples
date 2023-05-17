--
-- Gather statistics with histograms
--
exec dbms_stats.gather_table_stats(user,'t1',method_opt=>'for all columns size 254',no_invalidate=>false)
exec dbms_stats.gather_table_stats(user,'t2',method_opt=>'for all columns size 254',no_invalidate=>false)
