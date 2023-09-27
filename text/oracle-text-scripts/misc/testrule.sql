create table queries (
 query_id      number primary key,
 category      varchar2(40),
 query         varchar2(80)
);

insert into queries values (1,'Sports','tennis or football or soccer');
insert into queries values (2,'Health','cardiovascular medicine');

create index query_idx on queries(query) indextype is ctxsys.ctxrule;


create table news (
 newsid         number,
 author         varchar2(40),
 source         varchar2(30),
 category       varchar2(50),
 news_article   clob
);

set serverout on

create trigger mytrig 
before insert on 
begin
 for c in (select category from queries
           where matches(query, :new.news_article) > 0 )
 loop
   :new.category := c.category;
 end loop;
end;
/



