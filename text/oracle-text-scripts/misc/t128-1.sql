set timing on
set echo on

begin
  execute immediate ('drop table tab128k');
exception when others then null;
end;
/

create table tab128k
  (pk number primary key,
   num       number,
   the_date  date,
   text      varchar2(2000),
   concat    varchar2(1)
  );

declare
  cntr       integer;
  the_text   varchar2(2000);
  base_date  date     := '1-JAN-1990';
begin
  cntr := 0;
  loop
    the_text := 'this data is in row' || to_char(cntr);

    if mod (cntr, 2) = 0 then
      the_text := the_text || ' half';
    end if;

    if mod (cntr, 4) = 0 then
      the_text := the_text || ' quarter';
    end if;

    if mod (cntr, 10) = 0 then
      the_text := the_text || ' tenth';
    end if;

    if mod (cntr, 100) = 0 then
      the_text := the_text || ' hundredth';
      commit;
    end if;

    exit when cntr = 128 * 1024;
    insert into tab128k values (cntr, cntr/2, base_date+cntr/50, the_text, null);
    cntr := cntr + 1;
  end loop;
end;
/
commit
/
variable max_date varchar2(100)

begin
  select to_char(max(the_date),'DD-MON-YYYY')
  into :max_date 
  from tab128k;
end;
/
print max_date
