set echo on

drop table jtest;

create table jtest (text varchar2(2000), constraint textisjson check (text is json));

insert into jtest values ('{ "animal": "cat", "food": "fish" }');

create search index jsindex on jtest (text) for json;

-- works, finds a row
select * from jtest where json_textcontains(text, '$.food', 'fish');
-- works, does not find a row
select * from jtest where json_textcontains(text, '$.food', 'cat');
-- INCORRECT: finds a row when it shouldn't
select * from jtest where json_textcontains(text, '$.food', 'cat and fish');
-- fix it by surrounding whole term in parentheses
select * from jtest where json_textcontains(text, '$.food', '(cat and fish)');
 
-- the simple working query maps into this:

select * from jtest where contains (text, 'fish INPATH (//food)') > 0;

-- the incorrect query maps into this, but INPATH binds tighter than AND
-- so ANY 'cat' will match

select * from jtest where contains (text, 'cat and fish INPATH (//food)') > 0;

-- this is equivalent to 

select * from jtest where contains (text, 'cat and ( fish INPATH (//food) )') > 0;

-- whereas what we want is

select * from jtest where contains (text, '(cat and fish) INPATH (//food)') > 0;
