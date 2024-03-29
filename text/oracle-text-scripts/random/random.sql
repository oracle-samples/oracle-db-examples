
-- function to return a random integer between minval and maxval (inclusive)
-- need to call dbms_random.initialize and dbms_random.seed first

create or replace function random_int (minval integer, maxval integer) 
return integer is
begin
  return floor (dbms_random.value (minval-1, maxval))+1;
end;
/

