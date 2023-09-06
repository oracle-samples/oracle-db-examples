set pagesize 0
set linesize 255
set trimspool on
set long 500000
variable rpt clob
exec dbms_lob.createtemporary(:rpt, TRUE)
exec ctx_report.index_stats('FT_IDCTEXT2', :rpt)
spool indexstats.txt
print rpt
spool off
