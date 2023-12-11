connect / as sysdba
create user test default tablespace users quota unlimited on users identified by qj98zslh;
grant create session to test;
grant resource to test;
grant execute on CTXSYS.ctx_ddl to test;
grant execute on CTXSYS.ctx_cls to test;


