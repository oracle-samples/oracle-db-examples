set echo on

drop table ts;
create table ts (x varchar2(2000));
insert into ts values ('<html><head><title>Hello</title></head><body>World</body></html>');

create index tsi on ts(x) indextype is ctxsys.context
parameters ('filter ctxsys.null_filter section group ctxsys.null_section_group');
select token_text from dr$tsi$i;


exec ctx_ddl.drop_section_group('mysec')
exec ctx_ddl.create_section_group('mysec', 'NULL_SECTION_GROUP')

exec ctx_ddl.add_zone_section('mysec', 'head', 'head')

drop index tsi;
create index tsi on ts(x) indextype is ctxsys.context
parameters ('filter ctxsys.null_filter section group mysec');
select token_text from dr$tsi$i;

