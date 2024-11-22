drop table base_ngrams;
create table base_ngrams (gram varchar2(10), id number, pos number);

insert into base_ngrams values ('dog', 1, 10);
insert into base_ngrams values ('dog', 1, 20);
insert into base_ngrams values ('dog', 3, 5);
insert into base_ngrams values ('dog', 3, 9);
insert into base_ngrams values ('dog', 4, 12);
insert into base_ngrams values ('cat', 3, 7);

-- we want to return:
--   { "gram": "dog", 
--     "posting":[ 
--       {"id": 1, "pos": [10,20] }, 
--       {"id": 3, "pos": [5,9] }, 
--       {"id": 4, "pos": [12] } ] }
--   { "gram": "cat",
--     "posting": ["id": 3, "pos": [7] ] }

select distinct json_object(gram, 'posting' VALUE (
  select json_arrayagg(
    json_object(id, 'pos' VALUE (
      select json_arrayagg(pos)
      from base_ngrams i2
      where i2.id = i.id and i2.gram = o.gram) ) )
  from base_ngrams i
  where gram = o.gram) )
from base_ngrams o
/

select json_object(gram, 'posting' value 
    json_arrayagg(id))
from base_ngrams group by gram;

select json_object( gram, id, 'pos' value (json_arrayagg(pos))) from base_ngrams group by gram, id;

select json_object('posting' value 
   (json_arrayagg(
      json_object(id, 'pos' value (
        json_arrayagg(pos) ) ) ) ) ) 
from base_ngrams group by gram, id;


select distinct json_object (gram, 'posting' value (
  select json_arrayagg(
      json_object(id, 'pos' value (
        json_arrayagg(pos) ) ) )
  from base_ngrams where gram = o.gram 
  group by gram, id ) )
from base_ngrams o;

