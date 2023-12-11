drop table foo;
create table foo (id number, text varchar2(2000));

create unique index idind on foo(id);

create index fooind on foo(text) indextype is ctxsys.context parameters ('sync (on commit)');

drop sequence fooseq;
create sequence fooseq;

begin
    for i in 1..10000 loop
       insert into foo values (fooseq.nextval, 'the quick brown fox'||fooseq.currval);
    end loop;
    commit;
end;
/
set timing on
/
/
/
/
/
/
/
/
