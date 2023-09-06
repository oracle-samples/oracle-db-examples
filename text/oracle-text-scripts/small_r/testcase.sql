connect sys/password as sysdba

drop user rtest cascade;

create user rtest identified by rtest;
grant connect,resource,ctxapp,unlimited tablespace to rtest;

conn rtest/rtest

begin
  ctx_ddl.create_preference('wl_tdrborp1', 'BASIC_WORDLIST');
  ctx_ddl.set_attribute('wl_tdrborp1','SUBSTRING_INDEX', 'YES');
end;
/  


create table tab_tdrborp1(id number, data varchar2(200));

create index idx_tdrborp1 on tab_tdrborp1(data) indextype is ctxsys.context parameters ('wordlist wl_tdrborp1');


insert into tab_tdrborp1 values (1, 'oracle text');

insert into tab_tdrborp1 values (2, 'optimize rebuild');

insert into tab_tdrborp1 values (3, 'substring index');

insert into tab_tdrborp1 values (4, 'prefix index');


exec ctx_ddl.sync_index('idx_tdrborp1');


select count(*) from DR$IDX_TDRBORP1$P;

delete from tab_tdrborp1 where id in (1,2,4);

exec ctx_ddl.sync_index('idx_tdrborp1');
exec ctx_output.start_log('log_opt.txt');
exec ctx_ddl.optimize_index('idx_tdrborp1', 'full');
exec ctx_output.end_log;

select count(*) from DR$IDX_TDRBORP1$P;

