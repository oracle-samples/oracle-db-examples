set timing on

connect / as sysdba
grant ctxapp to scott;
alter session set current_schema = ctxsys;
@ctxdiag

connect scott/tiger
drop table ctx_tab purge;
create table ctx_tab (
  id   number,
  doc  varchar2(100));

declare
  i number;
begin
  for i in 1..10000 loop
    insert into ctx_tab values (
      i, 'hihohiho filler'||i);
    if mod(i, 1000) = 0 then
      commit;
    end if;
  end loop;
  commit;
end;
/

create index ctx_ind on ctx_tab(doc) 
  indextype is ctxsys.context;

-- validate $K against the base table
select *
from   dr$ctx_ind$k k
where  not exists (select 1 
                   from   ctx_tab t
                   where  k.textkey = t.rowid);

-- patch $K if necessary

-- validate $R against $K
select *
from   table(ctx_diag.decode_r('dr$ctx_ind$r')) r
where  not exists (select 1
                   from   dr$ctx_ind$k k
                   where  r.textkey = k.textkey);

-- zero out some slots in $R
delete from ctx_tab where id > 100 and id < 110;
commit;

-- try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler100 or filler101') > 0;

-- corrupt $R
declare
  v_loc   blob;
  v_buf   raw(4) := hextoraw('DEADBEEF');
begin
  select data into v_loc
    from dr$ctx_ind$r
   where row_no = 0
     for update;

  dbms_lob.write(v_loc, 4, 138, v_buf);
  commit;
end;
/

-- try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler10 or filler11') > 0;

-- validate $K against the base table
select *
from   dr$ctx_ind$k k
where  not exists (select 1 
                   from   ctx_tab t
                   where  k.textkey = t.rowid);

-- validate $R against $K
--   Note the CAST. This is necessary for invalid ROWIDs. This query is slower
--   than comparing ROWIDs but it will print invalid rows.
select *
from   table(ctx_diag.decode_r('dr$ctx_ind$r')) r
where  not exists (select 1
                   from   dr$ctx_ind$k k
                   where  r.textkey = cast(k.textkey as varchar2(18)));

-- rebuild $R
exec ctx_diag.k_to_r('dr$ctx_ind$k', 'dr$ctx_ind$r');

-- validate $R against $K
select *
from   table(ctx_diag.decode_r('dr$ctx_ind$r')) r
where  not exists (select 1
                   from   dr$ctx_ind$k k
                   where  r.textkey = k.textkey);

-- try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler10 or filler11') > 0;
