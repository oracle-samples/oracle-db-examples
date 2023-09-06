-- This file is an EXAMPLE of using the CTX_DIAG package
-- it creates an index in the SCOTT schema, intentionally damages it, then runs various checks against it.

-- it assumes the SCOTT schema already exists.  If it does not, then it can be created using the SQL

-- grant connect,resource,unlimited tablespace to scott identified by tiger;

set timing on

connect / as sysdba
grant ctxapp to scott;
alter session set current_schema = ctxsys;
@ctxdiag

connect scott/tiger
set echo on
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

REM validate $K against the base table
select *
from   dr$ctx_ind$k k
where  not exists (select 1 
                   from   ctx_tab t
                   where  k.textkey = t.rowid);

REM patch $K if necessary

REM validate $R against $K
select *
from   table(ctx_diag.decode_r('dr$ctx_ind$r')) r
where  not exists (select 1
                   from   dr$ctx_ind$k k
                   where  r.textkey = k.textkey);

REM zero out some slots in $R
delete from ctx_tab where id > 100 and id < 110;
commit;

REM try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler100 or filler101') > 0;

REM zero out $R slots manually
exec ctx_diag.clear_r('dr$ctx_ind$r', 100);

REM try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler100 or filler101') > 0;

REM corrupt $R
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

REM try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler10 or filler11') > 0;

REM validate $K against the base table
select *
from   dr$ctx_ind$k k
where  not exists (select 1 
                   from   ctx_tab t
                   where  k.textkey = t.rowid);

REM validate $R against $K
REM   Note the CAST. This is necessary for invalid ROWIDs. This query is slower
REM   than comparing ROWIDs but it will print invalid rows.
select *
from   table(ctx_diag.decode_r('dr$ctx_ind$r')) r
where  not exists (select 1
                   from   dr$ctx_ind$k k
                   where  r.textkey = cast(k.textkey as varchar2(18)));

REM rebuild $R
exec ctx_diag.k_to_r('dr$ctx_ind$k', 'dr$ctx_ind$r');

REM validate $R against $K
select *
from   table(ctx_diag.decode_r('dr$ctx_ind$r')) r
where  not exists (select 1
                   from   dr$ctx_ind$k k
                   where  r.textkey = k.textkey);

REM try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler10 or filler11') > 0;

REM corrupt $R (add duplicates ROWIDs)
declare
  v_loc   blob;
  v_buf   raw(14);
  v_siz   binary_integer := 14;
begin
  select data into v_loc
    from dr$ctx_ind$r
   where row_no = 0
     for update;

  dbms_lob.read(v_loc, v_siz, 127, v_buf);
  dbms_lob.write(v_loc, v_siz, 141, v_buf);
  commit;
end;
/

REM try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler10 or filler11') > 0;

REM validate $K against the base table
select *
from   dr$ctx_ind$k k
where  not exists (select 1 
                   from   ctx_tab t
                   where  k.textkey = t.rowid);

REM validate $R against $K
REM   Note the CAST. This is necessary for invalid ROWIDs. This query is slower
REM   than comparing ROWIDs but it will print invalid rows.
select *
from   table(ctx_diag.decode_r('dr$ctx_ind$r')) r
where  not exists (select 1
                   from   dr$ctx_ind$k k
                   where  r.textkey = cast(k.textkey as varchar2(18)));

REM validate $R (find duplicates)
column docids for a40
select textkey, listagg(docid, ', ') within group (order by docid) docids
from   table(ctx_diag.decode_r('dr$ctx_ind$r'))
group  by textkey
having count(*) > 1;

REM rebuild $R
exec ctx_diag.k_to_r('dr$ctx_ind$k', 'dr$ctx_ind$r');

REM validate $R against $K
select *
from   table(ctx_diag.decode_r('dr$ctx_ind$r')) r
where  not exists (select 1
                   from   dr$ctx_ind$k k
                   where  r.textkey = k.textkey);

REM try a query
column doc for a40
select * 
from   ctx_tab
where  contains(doc, 'filler10 or filler11') > 0;
