drop table testtab;
create table testtab (text varchar2(40));
insert into testtab values ('receipt');
insert into testtab values ('recidivism');
insert into testtab values ('recruitment');
insert into testtab values ('receivables');
insert into testtab values ('recievables');

create index testindex on testtab (text)
indextype is ctxsys.context;

select * from testtab where contains (text, '?(receevables)') > 0;

drop table xres;

create table xres (
       explain_id      varchar2(30),
       id              number,
       parent_id       number,
       operation       varchar2(30),
       options         varchar2(30),
       object_name     varchar2(64),
       position        number     );

begin 
   ctx_query.explain( 'testindex', '?(receivables)', 'xres');
end;
/

select lpad(' ',2*(level-1))||level||'.'||position||' '||
             operation||' '||
             decode(options, null, null, options || ' ') ||
             object_name plan
       from xres
       start with id = 1
       connect by prior id = parent_id; 


