drop table myjson;
create table myjson (id number primary key, data clob check (data is json));

insert into myjson values (1, '{"abc":123}');
insert into myjson values (2, '{"abc":456}');

drop materialized view myview;
create materialized view myview 
  refresh force on demand
  as
  select id, j.data.abc as abc from myjson j;

select * from myview;

insert into myjson values (3, '{"abc":999}');

select * from myview;

create or replace trigger mytrigger
after update 
  on myjson 
  for each row
begin
  if (json_value(:new.data, '$.abc') = 125) THEN
    dbms_mview.refresh('myview');
  end if;
end;
/
list 
show errors

update myjson set data = '{"abc":125}' where id = 1;

select * from myview;
