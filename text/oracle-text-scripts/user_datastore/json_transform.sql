set echo on

drop table jdocs;

create table jdocs(jtext varchar2(2000) constraint jtextisjson check (jtext is json));

insert into jdocs values (
 '{ "meta": 
       { "key":12345, "createdby": "john" },
    "info":
       { "title": "A Tale of Two Cities", "author": "Charles Dickens" }
  }'
);

select json_transform(j.jtext, KEEP '$.info' returning clob) from jdocs j;

create or replace procedure get_info_from_json 
   (rid     in            rowid,
    outclob in out nocopy clob
   ) is
begin
   select json_transform(j.jtext, KEEP '$.info' returning clob) into outclob
   from jdocs j where rowid = rid;
end;
/
list
show errors

exec ctx_ddl.drop_preference  ('my_datastore')
exec ctx_ddl.create_preference('my_datastore', 'USER_DATASTORE')
exec ctx_ddl.set_attribute    ('my_datastore', 'PROCEDURE', 'get_info_from_json')

create search index jdocsidx on jdocs(jtext) for json parameters ('datastore my_datastore');

select * from jdocs where json_textcontains(jtext, '$.*', 'Dickens');
select * from jdocs where json_textcontains(jtext, '$.*', 'John');

create table backup$i nologging as select * from dr$egp_item_text_ctx1$i;
create table backup$k nologging as select * from dr$egp_item_text_ctx1$k;
create table backup$n nologging as select * from dr$egp_item_text_ctx1$n;
create table backup$u nologging as select * from dr$egp_item_text_ctx1$u;

