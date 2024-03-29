variable query_buff varchar2(4000);
variable regexp_str varchar2(4000);

exec :regexp_str := '[QK]?UD[IEA]?R';
-- upper case because index terms are upper-cased by default

drop table ctest;

create table ctest (text varchar2(2000));

insert into ctest values ('khudayr');
insert into ctest values ('khudair');
insert into ctest values ('khudir');
insert into ctest values ('khuder');
insert into ctest values ('khudar');
insert into ctest values ('qudir');
insert into ctest values ('qudar');

create index ctest_index on ctest (text) indextype is ctxsys.context;

set serverout on size 1000000

begin
  for c in (select token_text from dr$ctest_index$i
           where regexp_like(token_text, :regexp_str) ) loop
    if length(:query_buff) > 0 then :query_buff := :query_buff || ' or '; end if;
    :query_buff := :query_buff || c.token_text;
  end loop;
  dbms_output.put_line('Query is: '||:query_buff);
end;
/

select * from ctest where contains (text, :query_buff) > 0;
