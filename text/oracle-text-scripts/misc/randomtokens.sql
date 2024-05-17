create table tokens2 as select * from tokens;

create table tokens3 as select * from tokens2 where 1=2;

declare
  cnt integer := 0;
  r   integer := 0;
begin
  select count(*) into cnt from tokens2;

  while (cnt > 0) loop
    r := random_int(1,cnt);

    insert into tokens3 
      select cnt, token_text from tokens2 where pk=r;
    delete from tokens2 where pk=r;
    update tokens2 set pk = rownum;

    cnt := cnt - 1;

  end loop;

end;
/

