drop table a;
drop table b;

create table a (x varchar2(3), y varchar2(3));
create table b (p varchar2(3), q varchar2(3));

insert into a values ('foo', 'bar');
insert into b values ('foo', 'baz');

create index ax on a(x) indextype is ctxsys.context;

-- works
select * from a,b
where contains (x, 'foo') > 0;

-- doesn't work
select * from a,b
where contains (x, b.p) > 0;

