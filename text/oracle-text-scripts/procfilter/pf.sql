-- procedure filter example
-- demonstrates a dummy procedure which changes all lowercase "i"
-- to "E" then upper cases the rest
-- Invokes INSO_FILTER via "ctx_doc.ifilter" to deal with formatted files

connect ctxsys/ctxsys
create or replace procedure myprocfilter(inblob blob, outclob in out nocopy clob) is
  buff      varchar2(32767);
  pos       int := 1;
  readlen   int;
  tlob      clob;
begin
  ctx_doc.ifilter(inblob, outclob);
  dbms_lob.createtemporary(tlob, cache=>true);
  begin
     loop
        readlen := 32767;
        dbms_lob.read(outclob, readlen, pos, buff);
        pos := pos + readlen;
        buff := translate (buff, 'i', 'E');
        buff := upper(buff);
        dbms_lob.writeappend(tlob, readlen, buff);
     end loop;
  exception
     when no_data_found then null;
  end;
  dbms_lob.copy(outclob, tlob, dbms_lob.getlength(tlob));
  dbms_lob.freetemporary(tlob);
end;
/
show errors

grant execute on myprocfilter to roger
/

connect roger/roger

drop table mydocs
/
exec ctx_ddl.drop_preference('mypf')
exec ctx_ddl.drop_preference('fileDS')

create table mydocs (title varchar2(80), docfile varchar2(80))
/

insert into mydocs values ('title for rec1', 'h:\auser\work\code\filterserver\doc1.doc')
/

exec ctx_ddl.create_preference('fileDS', 'FILE_DATASTORE')

exec ctx_ddl.create_preference('mypf', 'procedure_filter')
exec ctx_ddl.set_attribute('mypf', 'procedure', 'myprocfilter')
exec ctx_ddl.set_attribute('mypf', 'input_type', 'blob')

create index mydocs_index on mydocs(docfile) indextype is ctxsys.context 
parameters('datastore fileDS filter mypf')
/

select * from ctx_user_index_errors
/

select token_text from dr$mydocs_index$i
/




