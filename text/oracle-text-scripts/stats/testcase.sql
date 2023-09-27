drop user u1 cascade;
drop user u2 cascade;

grant connect,resource,ctxapp,unlimited tablespace to u1 identified by u1;
grant connect,resource,ctxapp,unlimited tablespace to u2 identified by u2;

-- grant select any table to u2;

connect u1/u1

create table t(c varchar2(200));
insert into t values ('hello world');

create index i on t(c) indextype is ctxsys.context;

exec ctx_output.enable_query_stats(i)

grant select on t to u2;

connect u2/u2

select * from u1.t where contains (c, 'hello') > 0;

select token_text from u1.dr$i$i;

variable c clob

exec dbms_lob.createtemporary(:c, true)
exec ctx_report.index_stats('u1.i', :c)

print c

exec ctx_report.index_stats('u1.i', :c, stat_type => 'EST_FREQUENT_TOKENS', list_size=>100)
