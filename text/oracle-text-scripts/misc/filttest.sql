drop table x;

create table x (x varchar2(2000));

insert into x values('c:\hello.txt');

create index xi on x(x) indextype is ctxsys.context
parameters ('filter ctxsys.null_filter');

select token_text from dr$xi$i;

alter index xi rebuild parameters ('replace filter ctxsys.inso_filter');
