alter session set plsql_warnings = 'error:all';

create or replace function myreport return clob authid definer as
  output    clob;
begin

  dbms_lob.createtemporary(output, true);
  
  for i in 1..2 loop
    output := output || 'x';
  end loop;

  output := output || 'String with a number appended '||123;
	
  return output;
  
end;
/
-- list
show err

select myreport from dual;
