set echo on

drop table empj;
create table empj(empdata json);

insert into empj values ('{ "name":"john", "salary":1500, "qualifications": "PhD in physics, Msc math"}');

-- create explain plan table
@?/rdbms/admin/utlxpls

-- search without index
explain plan for select * from empj e where e.empdata.salary.number() > 1000;

select * from table(dbms_xplan.display);

-- create index
create search index emp_search on empj(empdata) for json;

-- search with index
explain plan for select * from empj e where e.empdata.salary.number() > 1000;

select * from table(dbms_xplan.display);

select e.empdata.name from empj e where json_textcontains(empdata, '$.qualifications', 'physics');

select e.empdata.name from empj e where json_textcontains(empdata, '$.qualifications', 'physics AND msc math');

select e.empdata.name from empj e where json_textcontains(empdata, '$.qualifications', 'fuzzy(phisiks)');

insert into empj values ('{ "name":"bill", "salary":1000, "qualifications": "Math professor"}');

insert into empj values ('{ "name":"mike", "salary":2000, "qualifications": "Physics student"}');

commit;
exec dbms_session.sleep(3)

select score(1), e.empdata.name from empj e
where json_textcontains(empdata, '$.qualifications', 'math ACCUM physics', 1);
