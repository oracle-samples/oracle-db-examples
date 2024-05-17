-- simple example of a JSON search index

connect sys/oracle as sysdba
alter session set container=r122b;
alter session set current_schema=roger;

create table jsontest (jsondata varchar2(2000) constraint ensure_json check (jsondata is json));

insert into jsontest values ('{ "ID" : 123, "Quote" : "the quick brown fox" }');
create search index jsonindex on jsontest(jsondata) for json;

select * from jsontest where json_textcontains(jsondata, '$.Quote', 'fox');
