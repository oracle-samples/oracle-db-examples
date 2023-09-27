drop table testtab;
create table testtab (text varchar2(40));
insert into testtab values ('receipt');
insert into testtab values ('recidivism');
insert into testtab values ('recruitment');
insert into testtab values ('receivables');
insert into testtab values ('recievables');


begin
  for i in 1..30000 loop
    insert into testtab values ('FOOABF-CU DE LISERE-CG0'||i);
  end loop;
end;
/

exec ctx_ddl.drop_preference  ('wl50k')
exec ctx_ddl.create_preference('wl50k', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute    ('wl50k', 'WILDCARD_MAXTERMS', '50000')

exec ctx_ddl.drop_preference  ('wl100')
exec ctx_ddl.create_preference('wl100', 'BASIC_WORDLIST')
exec ctx_ddl.set_attribute    ('wl100', 'WILDCARD_MAXTERMS', '100')

create index testindex on testtab (text)
indextype is ctxsys.context
parameters ('wordlist wl50k');

alter index testindex parameters ('replace metadata wordlist wl100');

--select * from testtab where contains (text, '?(receevables)') > 0;

select count(*) from testtab where contains (text, '%FOOABF\-CU DE LISERE\-CG%') > 0;

drop table xres;

create table xres (
       explain_id      varchar2(30),
       id              number,
       parent_id       number,
       operation       varchar2(30),
       options         varchar2(30),
       object_name     varchar2(64),
       position        number     );

--begin 
--   ctx_query.explain( 'testindex', '?(receivables)', 'xres');
--end;
--/

begin 
   ctx_query.explain( 'testindex', '%FOOABF\-CU DE LISERE\-CG0%', 'xres');
end;
/

select lpad(' ',2*(level-1))||level||'.'||position||' '||
             operation||' '||
             decode(options, null, null, options || ' ') ||
             object_name plan
       from xres
       start with id = 1
       connect by prior id = parent_id; 


