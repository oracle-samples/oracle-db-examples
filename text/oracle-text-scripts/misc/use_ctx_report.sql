declare
  theclob clob;
  buff    varchar2(32767);
  tot     number := 0;
  amt     number := 255;
  siz     number := 0;
begin
  ctxsys.ctx_report.index_size('reuters_index', theclob);
  siz := dbms_lob.getlength(theclob);
  dbms_lob.open(theclob, dbms_lob.lob_readonly);
  loop
    dbms_lob.read(theclob, amt, tot+1, buff);
    tot := tot + amt;
    exit when tot >= siz;
    dbms_output.put_line(buff);
    amt := 255;
  end loop;
end;
/
