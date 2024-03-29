create or replace function get_fragpercent( indexname varchar2 ) return number is
  tlob clob;
  fragpercent number;
begin
  ctx_report.index_stats(
     index_name=>indexname, report=>tlob, 
     list_size=>20, report_format=>'XML');
  select rtrim( extractValue(xmltype(tlob), 
     '//STAT_STATISTIC[@NAME="estimated row fragmentation"]'), '%' )
     into fragpercent
     from dual;
  dbms_lob.freetemporary(tlob);
  return fragpercent;
end;
/
