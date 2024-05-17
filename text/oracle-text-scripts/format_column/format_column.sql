-- a FORMAT column can be used to specify whether particular rows should
-- be indexed or ignored

drop table x;

create table x (text varchar2(60), fmt varchar2(10));

insert into x values ('the quick brown fox', 'TEXT');
insert into x values ('the slow red fox', 'IGNORE');
insert into x values ('the great big fox', 'TEXT');

create index xi on x (text) indextype is ctxsys.context
parameters ('format column fmt')
/

select * from x where contains(text, 'fox') > 0;
