-- must do the following grants to user running this:
-- grant execute on dbms_lock to <user>;
-- grant execute on dbms_mview to <user>;
-- grant create job to <user>;

set echo on
column abc format a20
column foo format a20
column data format a30

-- base table 
drop table mytable;
create table mytable (id number primary key, text varchar2(20), data clob check (data is json));

insert into mytable values (1, 'hello', '{"abc":123, "foo":"bar"}');
insert into mytable values (2, 'world', '{"abc":456}');

-- materialized view with refresh on demand
drop materialized view myview;
create materialized view myview 
  refresh force on demand
  as
  select id, text, j.data.abc as abc, j.data.foo as foo from mytable j;

-- select from the view
select * from myview;

-- scheduler job to refresh view
exec dbms_scheduler.drop_job('mview_refresh' )
begin
  dbms_scheduler.create_job (
    job_name   => 'mview_refresh',
    job_type   => 'PLSQL_BLOCK',
    job_action => 'begin dbms_mview.refresh(''myview''); end;'
    );
end;
/

-- trigger will only update the view if JSON value abc changes
create or replace trigger mytrigger
after update 
  on mytable 
  for each row
begin
  if (json_value(:new.data, '$.abc') != json_value(:old.data, '$.abc')) THEN
    dbms_scheduler.run_job('mview_refresh', true);
  end if;
end;
/

-- first update just changes the text of ID=1 to 'goodbye', view is not refreshed 
update mytable set text = 'goodbye' where id = 1;
commit;

-- wait 5 seconds for job to complete (if it runs)
exec dbms_lock.sleep(5)
select * from mytable;
select * from myview;

-- second update changes the abc value in the json to 999. View IS refreshed
update mytable set data = '{"abc":999}' where id = 1;
commit;

exec dbms_lock.sleep(5)
select * from mytable;
select * from myview;

-- third update changes the JSON but doesn't change abc. View is not refreshed
update mytable set data = '{"foo":"fum", "abc":999}' where id = 1;
commit;

exec dbms_lock.sleep(5)
select * from mytable;
select * from myview;
