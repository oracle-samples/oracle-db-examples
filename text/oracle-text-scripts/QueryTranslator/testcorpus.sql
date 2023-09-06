-- does it match or not tests
set serverout on

drop table qlog;
create table qlog (t clob);

drop table t1;
create table t1 (t varchar2(2000));

create or replace procedure ftest (data varchar2, srch varchar2, joins varchar2 default null) is
   counter number := 0;
   q       varchar2(4000);
begin
   begin
     execute immediate ('drop table t1');
   exception when others then null;
   end;
   execute immediate ('create table t1 (t varchar2(200))');
   begin
      ctx_ddl.drop_stoplist('empty_stop');
   exception when others then null;
   end;
   ctx_ddl.create_stoplist('empty_stop');
   execute immediate ('insert into t1 values (''' ||data|| ''')');
   begin
     ctx_ddl.drop_preference('p1');
   exception when others then null;
   end;
   ctx_ddl.create_preference('p1', 'basic_lexer');
   if (length (joins) > 0) then
     ctx_ddl.set_attribute('p1', 'printjoins', joins);
   end if;
   execute immediate ('create index t1i on t1(t) indextype is ctxsys.context parameters (''lexer p1 stoplist empty_stop'')');

   -- Query part

   q := ubparse.OTSimpleSearch(srch);
--   q := ubparse.OTProgRelax(srch);
   delete from qlog;
   insert into qlog values (q);
   for c in (select score(1) s, t from t1 where contains (t, q, 1) > 0) loop
      counter := counter + 1;
      dbms_output.put_line (to_char(rpad(4,c.s)) || c.t);
   end loop;
   dbms_output.put_line('Row count: '||counter);
end;
/

   
