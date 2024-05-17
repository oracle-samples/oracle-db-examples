drop table table4;

create table table4(id number, text varchar2(4000));

insert into table4 values(1,'Ab Be');
insert into table4 values(2,'Ab Cd');
commit;

create index index1 on table4(text) indextype is ctxsys.ctxrule
parameters ('stoplist ctxsys.empty_stoplist');

select * from dr$index1$I;

select * from table4 where matches (text, 'ab be') > 0;
select * from table4 where matches (text, 'ab') > 0;

