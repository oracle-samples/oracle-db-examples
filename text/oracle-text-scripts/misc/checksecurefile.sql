set serverout on

define TABNAME=dollarrcopy

declare
  myblob blob;
begin
  select data into myblob from &TABNAME where rownum = 1;
  if (dbms_lob.issecurefile(myblob)) then
    dbms_output.put_line('Blob is securefile');
  else
    dbms_output.put_line('Blob is basicfile');
  end if;
end;
/
