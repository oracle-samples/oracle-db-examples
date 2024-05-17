-- function to return a random integer between minval and maxval (inclusive)
-- need to call dbms_random.initialize and dbms_random.seed first

create or replace function random_int (minval integer, maxval integer) 
return integer is
begin
  return floor (dbms_random.value (minval-1, maxval))+1;
end;
/

-- list
show errors

-- test it

create table random (num number)
/
delete from random
/

begin
  for i in 1 .. 10000 loop
    insert into random select random_int(1,3) from dual;
  end loop;
end;
/

select num, count(*) from random group by num
/
