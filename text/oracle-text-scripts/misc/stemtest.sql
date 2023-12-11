drop table xx;
create table xx (text varchar2(2000));

insert into xx values ('There are many countries in Europe.');

create index xxi on xx(text) indextype is ctxsys.context;

select text from xx where contains (text, '$country') > 0;
