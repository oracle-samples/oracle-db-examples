-- how to create a standard text index on basic JSON content
-- the JSON is decomposed using JSON_VALUE and the multicolumn datastore
-- automatically creates tags around each value based on the column alias
-- (e.g. " as review" creates a review section)

drop table reviews_json;

create table reviews_json
  (pid number  primary key,
   json_text   clob,
   constraint reviewtextisjson check (json_text is json));

insert into reviews_json values (1, '{ "title":"the greatest thing", "review": "this stuff is fantastic" }');

insert into reviews_json values (2, '{ "title":"awful", "review": "this stuff is just terrible" }');


exec ctx_ddl.drop_preference  ('json_ds')
exec ctx_ddl.create_preference('json_ds', 'MULTI_COLUMN_DATASTORE')
begin
   ctx_ddl.set_attribute    (
      'json_ds', 
      'COLUMNS', 
      'json_value(json_text, ''$.title'') as title,
json_value(json_text, ''$.review'') as review'
   );
end;
/

create index reviews_text_index 
   on reviews_json(json_text) 
   indextype is ctxsys.context
   parameters ('section group ctxsys.auto_section_group');

-- simple contains query
select * from reviews_json
where contains (json_text, 'greatest') > 0;

-- within query to only find within specific JSON element
select * from reviews_json
where contains (json_text, 'stuff') > 0;
