-- in 19c, JSON_TEXTCONTAINS doesn't support SCORE
-- but you can still get a score by reverting to CONTAINS syntax, and specifying
-- the JSON path using an INPATH operator. See example:

drop table myjson;

create table myjson (jtext varchar2(2000) constraint jj check(jtext is json));

insert into myjson values ('{ "salutation": "hello", "audience": "world" }');
insert into myjson values ('{ "salutation": "howdy", "audience": "world" }');
insert into myjson values ('{ "salutation": "hello", "audience": "planet" }');

create search index myjsonindex on myjson(jtext) for json;

select * from myjson where json_textcontains (jtext, '$.salutation', 'hello');

select * from myjson where contains (jtext, 'hello inpath (/salutation)') > 0;

column jtext format a50
select score(99), jtext from myjson 
   where contains (jtext, 
    '( hello inpath (/salutation) )*2 OR ( world inpath (/audience) ) *1', 99 ) > 0;


