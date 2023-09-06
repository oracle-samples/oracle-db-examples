set echo on
connect / as sysdba

-- enable small_r in 12.1
alter system set events '30579 trace name context forever, level 268435456';

drop user newuser cascade;

grant connect,resource,ctxapp,unlimited tablespace to newuser identified by newuser;

@ctxdiag

connect newuser/newuser

exec ctx_ddl.create_preference('mystorage','BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('mystorage', 'SMALL_R_ROW', 'T')

create table t (id number primary key, c varchar2(200));

begin
  for i in 1..36000 loop
    insert into t values (i, 'x'||i);
  end loop;
end;
/

create index i on t(c) indextype is ctxsys.context parameters ('storage mystorage');

update t set c = c where rowid = 
  (select textkey from dr$i$k where docid = 35000);

select row_no, length(data) from dr$i$r;

exec ctx_ddl.sync_index('i')

select row_no, length(data) from dr$i$r;

delete from dr$i$r where row_no = 1;

commit;

exec ctx_diag.k_to_r('dr$i$k','dr$i$r',35000,TRUE)

select row_no, length(data) from dr$i$r;
