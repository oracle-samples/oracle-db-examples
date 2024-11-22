set timing on
set echo on

begin
  execute immediate ('drop table tab256k');
exception when others then null;
end;
/

create table tab256k
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

    exit when cntr = 256;
    insert into tab256k values (cntr, cntr, base_date+cntr, the_text, null);
    cntr := cntr + 1;
  end loop;
end;
/
commit
/
variable max_date date;
begin
  select to_char(max(the_date),'DD-MON-YYYY')
  into :max_date 
  from tab256k;
end;
/
print max_date

begin
  ctx_cd.drop_cdstore('t256k');
exception when others then null;
end;
/

exec ctx_cd.create_cdstore('t256k', 'tab256k')

begin
  ctx_cd.add_column ( 't256k', 'text' );
  ctx_cd.add_column ( 't256k', 'num', 
      min_int => 0, max_int => 65535, visible=>false);
  ctx_cd.add_column ( 't256k', 'the_date', 
      min_date => '1-JAN-1990', max_date => :max_date, visible=>false);
end;
/

create index t256k_num    on tab256k (num);

create index t256k_date   on tab256k (the_date);

create index t256k_text   on tab256k (text)
  indextype is ctxsys.context;

create index t256k_concat on tab256k (concat)
  indextype is ctxsys.context parameters
  ('datastore t256k section group t256k');

