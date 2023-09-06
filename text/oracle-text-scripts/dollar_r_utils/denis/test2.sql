set echo on
connect / as sysdba

-- enable small_r in 12.1
alter system set events '30579 trace name context forever, level 268435456';

drop user fusion cascade;

grant connect,resource,ctxapp,unlimited tablespace to fusion identified by fusion;

@ctxdiag

connect fusion/fusion

exec ctx_ddl.create_preference('mystorage','BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('mystorage', 'SMALL_R_ROW', 'T')

create table t (id number primary key, c varchar2(200));

begin
  for i in 1..36000 loop
    insert into t values (i, 'x'||i);
  end loop;
end;
/

create index EGP_ITEM_TEXT_TL_CTX1 on t(c) indextype is ctxsys.context parameters ('storage mystorage');

connect / as sysdba

@../../small_r/small_r_conversion3.sql

exec small_r_convert.convert_index('FUSION','EGP_ITEM_TEXT_TL_CTX1')

insert into t values ('hello world')

exec ctx_ddl.sync_index('EGP_ITEM_TEXT_TL_CTX1')

select row_no, length(data) from DR$EGP_ITEM_TEXT_TL_CTX1$R;

@convback

connect fusion/fusion

select row_no, length(data) from DR$EGP_ITEM_TEXT_TL_CTX1$R;

select * from t where contains (c, 'x35999') > 0;
