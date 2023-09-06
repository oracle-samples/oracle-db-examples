-- example of DETAIL DATASTORE useage

drop table mydocs;
drop table mydoclines;

create table mydocs(id number primary key, title varchar2(20));

create table mydoclines(masterid number, linenumber number, linetext varchar2(80));

insert into mydocs values (1, 'partydoc');

insert into mydoclines values (1, 1, 'now is the time');
insert into mydoclines values (1, 2, 'for all good men');
insert into mydoclines values (1, 3, 'to come to the aid of the party');

insert into mydocs values (2, 'foxdoc');

insert into mydoclines values (2, 1, 'the quick brown fox');
insert into mydoclines values (2, 2, 'jumps over the lazy dog');

exec ctx_ddl.drop_preference  ('mydds')
exec ctx_ddl.create_preference('mydds', 'DETAIL_DATASTORE')
exec ctx_ddl.set_attribute    ('mydds', 'DETAIL_TABLE', 'mydoclines')
exec ctx_ddl.set_attribute    ('mydds', 'DETAIL_LINENO', 'linenumber')
exec ctx_ddl.set_attribute    ('mydds', 'DETAIL_KEY', 'masterid')
exec ctx_ddl.set_attribute    ('mydds', 'DETAIL_TEXT', 'linetext')

create index mydocsindex on mydocs(title)
indextype is ctxsys.context
parameters ('datastore mydds');

select token_text from dr$mydocsindex$i;

select * from mydocs where contains(title, 'lazy') > 0;

select * from mydocs where contains(title, 'party') > 0;
