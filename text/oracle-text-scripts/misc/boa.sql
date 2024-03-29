drop table foo;

create table foo (
 colname1 varchar2(2000),
 colname2 varchar2(2000),
 colname3 varchar2(2000),
 colname100 varchar2(2000)
);

insert into foo values ('this is column1', 'this is column2', 'this is column3', 'this is column100');
insert into foo values ('xcolumn1', 'xcolumn2', 'xcolumn3', 'xcolumn100');

-- create the user datastore procedure

create or replace procedure my_user_datastore_proc (rid rowid, outclob in out nocopy clob) is 
  type    column_list is table of varchar2(30); 
  collist column_list;
  res     varchar2(4000);
  sqlstr  varchar2(4000);
begin
  -- initialize the column list and allow for four entries
  collist := column_list();
  collist.extend(4);

  collist(1) := 'colname1';
  collist(2) := 'colname2';
  collist(3) := 'colname3';
-- ...
  collist(4) := 'colname100';

  outclob := '';

  for i in 1..collist.count loop

     sqlstr := 'select ' || collist(i) || ' from foo where rowid = :1';
     -- dbms_output.put_line( sqlstr );
     execute immediate sqlstr into res using rid;
     -- concatenate the column contents with marker tags around it
     outclob := outclob || '<' || collist(i) || '>' || res || '</' || collist(i) || '>' || chr(10);

  end loop;

end;
/
list
show errors

-- this is purely to test the user datastore procedure

set serveroutput on size 1000000

declare
  myclob clob;
begin
  -- initialize the lob
  dbms_lob.createtemporary(myclob, true);
  -- loop over all the rows in the table calling the user datastore for each
  for c in ( select rowid from foo ) loop
    my_user_datastore_proc( c.rowid, myclob );
    dbms_output.put_line(myclob);
  end loop;
end;
/

-- now create the index

exec ctx_ddl.drop_preference     ( 'my_datastore' )
exec ctx_ddl.create_preference   ( 'my_datastore', 'user_datastore' )
exec ctx_ddl.set_attribute       ( 'my_datastore', 'procedure', 'my_user_datastore_proc' ) 

exec ctx_ddl.drop_section_group  ( 'my_sec_group' )
exec ctx_ddl.create_section_group( 'my_sec_group', 'AUTO_SECTION_GROUP' )

create index foo_index on foo( colname1 ) indextype is ctxsys.context
parameters ('datastore my_datastore section group my_sec_group memory 100M');

-- don't forget you'll need a trigger to update colname1 if any of the other columns change

-- now run some queries

select colname1 from foo where contains (colname1, 'column1 AND (column2 WITHIN colname2) AND column100') > 0;

select colname3 from foo where contains (colname1, 'xcolumn3 WITHIN colname3') > 0;