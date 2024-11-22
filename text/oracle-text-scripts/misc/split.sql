-- do fuzzy against multiple words

create or replace function qproc (q varchar2) return varchar2 is
  i integer;
  my_string  varchar2(2000) := q;
  outstr     varchar2(2000) := '';
  first_time boolean        := TRUE;
begin
  for current_row in (
    with test as    
      (select my_string from dual)
      select regexp_substr(my_string, '[[:alnum:]]+', 1, rownum) split
      from test
      connect by level <= length (regexp_replace(my_string, '[[:alnum:]]+'))  + 1)
  loop
    dbms_output.put_line(current_row.split);
    if first_time then 
      outstr := outstr||'FUZZY(('||current_row.split||'),,,WEIGHT)>50 ';
      first_time := FALSE;
    else
      outstr := outstr||'ACCUM FUZZY(('||current_row.split||'),,,WEIGHT)>50 ';
    end if;
  end loop;
  return outstr;
end;
/
list 
show errors
