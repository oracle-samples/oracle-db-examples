drop table myjson;
create table myjson (cjson clob check (cjson is json));

declare
  myclob clob;
begin
  myclob := '{ ';
  for i in 1 .. 10000 loop
    dbms_lob.append(myclob, '''foo'||i||''': 1, ');
  end loop;
  dbms_lob.append(myclob, '''foolast'': 1 }');

  insert into myjson values (myclob);
--  dbms_output.put_line(myclob);
end;
/

select dbms_lob.getlength(cjson) from myjson;
    
create or replace function clob_to_blob(inclob clob) return blob is
  vraw   raw(32767);
  vblob  blob;
  amount integer := 16383;
  offset integer := 1;
begin
  dbms_lob.createtemporary(vblob, true);
  loop
    vraw := utl_raw.cast_to_raw( dbms_lob.substr(inclob, amount, offset) );
    offset := offset + 16383;
    exit when vraw is null;
    dbms_lob.append(vblob, vraw);
  end loop;
  return vblob;
end;
/
list
show errors

drop table myblobjson;
create table myblobjson(bjson blob check (bjson is json));

insert into myblobjson select clob_to_blob(cjson) from myjson;

select t.bjson.foo1 from myblobjson t;
