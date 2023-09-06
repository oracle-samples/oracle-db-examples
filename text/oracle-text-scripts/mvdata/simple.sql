connect / as sysdba

drop user mvtest cascade;

grant connect,resource,ctxapp,alter session,unlimited tablespace to mvtest identified by mvtest;

connect mvtest/mvtest

create table t(c varchar2(2000));

insert into t values ('hello <mvd1>123</mvd1><mvd2>234</mvd2>');

alter session set events '30579 trace name context forever, level 2';

exec ctx_ddl.create_section_group('sg', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_mvdata_section('sg', 'mvd1', 'mvd1')
exec ctx_ddl.add_mvdata_section('sg', 'mvd2', 'mvd2')

exec ctx_ddl.create_preference('stor', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute('stor', 'BIG_IO', 'TRUE')

create index i on t(c) indextype is ctxsys.context parameters ('section group sg storage stor sync(on commit)');

select token_text,token_type from dr$i$i;

insert into t values ('hello <mvd1>123</mvd1><mvd2>234</mvd2>');

insert into t values ('hello <mvd1>123</mvd1><mvd2>234</mvd2>');

insert into t values ('hello <mvd1>456</mvd1><mvd2>789</mvd2>');

commit;

select token_text,token_type from dr$i$i;

exec ctx_output.start_log('mylog.txt')
exec ctx_output.add_event(ctx_output.event_opt_print_token)

exec ctx_ddl.optimize_index('i', 'FULL')

exec ctx_output.end_log
