set serveroutput on size 1000000

define TABLE_NAME=foo
define INDEX_NAME=fooindex

declare 
  buff    raw(14);
  myblob  blob;
  amount  integer := 14;
  offset  integer := 1;
  txt     varchar2(200);
begin
  select data into myblob from dr$&INDEX_NAME.$r;
  dbms_lob.open ( myblob, dbms_lob.LOB_READONLY );
  while amount = 14 loop
    dbms_lob.read ( myblob, amount, offset, buff );
    offset := offset + 14;
    txt := utl_raw.cast_to_varchar2(buff);
    dbms_output.put_line(txt);
  end loop;
  exception
      when no_data_found then 
          dbms_lob.close( myblob );
end;
/

