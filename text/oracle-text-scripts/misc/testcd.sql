create table mytable (pk number primary key, title varchar2(30), text varchar2(2000));

insert into mytable values (
 1,
 'The Big Dog',
 'We have full employment. Youth figures are not included.')
/

exec ctx_cd.create_cdstore('quick', 'mytable');
exec ctx_cd.add_column('quick', 'title');
exec ctx_cd.add_column('quick', 'text');

exec ctx_ddl.add_special_section('quick', 'sentence');

create index quick_any_idx on mytable (text)
indextype is ctxsys.context
parameters ('datastore quick section group quick');

select text from mytable 
where contains (text, 'employment youth') > 0;

select text from mytable 
where contains (text, '(employment youth) within sentence') > 0;
