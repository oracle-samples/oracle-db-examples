-- show how to migrate JSON data from a CLOB to a BLOB column
-- not clear whether this is safe on a SODA collection

--drop table foo;

create table foo(c clob, constraint c_is_json check(c is json));

insert into foo values ('{ "salutation":"hello", "target":"word" }');

-- insert a value longer than 32Kb to make sure the "set blob=clob" operation
-- isn't limited to 32kb:

declare
  x clob;
begin
  x := '{''x0'':0';
  for i in 1..4000 loop
    dbms_lob.append(x, ',''x'||i||''':0');
  end loop;
  dbms_lob.append(x, '}');
  insert into foo values (x);
end;
/

-- note that getlength returns length in chars, there's no easy 
-- way to get the length in bytes
select dbms_lob.getlength(c) from foo;

-- add a BLOB column
alter table foo add (b blob);
alter table foo add constraint b_is_json check(b is json);

-- set blob=clob
update foo set b=c;

-- rename columns so the BLOB column is now C
alter table foo rename column c to old_c;
alter table foo rename column b to c;

-- check the inserts worked
select dbms_lob.getlength(c) from foo;
select substr(json_serialize(c),1, 100) from foo;

-- and remove the old CLOB column
alter table foo drop column old_c;


