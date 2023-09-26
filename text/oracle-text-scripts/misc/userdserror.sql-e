connect system/welcome1

alter user scott account unlock identified by tiger;
grant connect,resource,ctxapp to scott;

connect scott/tiger;

drop table address;
create table address (id number primary key, address varchar2(300));

drop table person;
create table person (id number primary key, name varchar2(300), address_id number references address(id));

insert into address values (99, '1 High Street, Anywhere, UK');
insert into person values (1, 'John Smith', 99);

drop table control_table;

create table control_table (error_flag number);

insert into control_table values (0);

commit;

create or replace procedure my_proc 
     (rid in rowid, tlob in out nocopy clob) is
   errflag number; 
begin 
     -- this "for loop" will only execute once but it's easier this way than declaring a 
     -- separate cursor
     for c in ( select p.name, a.address from
                person p, address a
                where a.id = p.address_id 
                and p.rowid = rid ) loop
         dbms_lob.write(tlob, length('<name>'), 1, '<name>');
         dbms_lob.writeappend(tlob, length(c.name), c.name);
         dbms_lob.writeappend(tlob, length('</name>'), '</name>');

         dbms_lob.writeappend(tlob, length('<address>'), '<address>');
         dbms_lob.writeappend(tlob, length(c.address), c.address);
         dbms_lob.writeappend(tlob, length('</address>'), '</address>');
         select error_flag into errflag from control_table;
         if errflag = 1 then
            select 1/0 into errflag from dual;
         end if;
     end loop;
end; 
/
list
show errors

exec ctx_ddl.drop_preference('my_datastore')

exec ctx_ddl.create_preference('my_datastore', 'user_datastore')
exec ctx_ddl.set_attribute('my_datastore', 'procedure', 'my_proc')

create index mytestindex on person (name)
indextype is ctxsys.context
parameters('datastore my_datastore section group ctxsys.auto_section_group sync (on commit)');

-- need to do this periodically
exec ctx_ddl.optimize_index('mytestindex', 'FULL')

-- check for errors during indexing
select * from ctx_user_index_errors;

update control_table set error_flag = 1;

update person set name=name;

commit;

select * from ctx_user_index_errors;

-- test
select * from person where contains (name, '(high street) within address and smith within name')>0;

update control_table set error_flag = 0;

insert into address values (101, '1 High Street, Anywhere, UK');
insert into person values (2, 'John W. Smith', 101);

commit;

select * from ctx_user_index_errors;
