
-- function to reverse the order of a string

create or replace function reverse_string( str varchar2 ) 
    return varchar2 
    deterministic 
is
  buff varchar2(32767) := '';
  len  integer;
begin
  len := length( str );
  for i in 1..len loop
    buff := buff || substr( str, len - (i-1), 1 );
  end loop;
  return buff;
end;
/
list
show err

-- test the function

select reverse_string('>' || 'hello world' || '<') from dual;

-- create and populate a test table

drop table foo;
create table foo (bar varchar2(2000));

begin
  for i in 1 .. 100000 loop
    insert into foo values ('abc'||i);
  end loop;
end;
/

-- create function-based index

create index bar_reverse_index on foo (reverse_string(bar));

-- run a query

select * from foo where reverse_string(bar) like reverse_string('%1234');

-- prove it used the index

set autotrace on traceonly 

select * from foo where reverse_string(bar) like reverse_string('%1234');

set autotrace off


     
