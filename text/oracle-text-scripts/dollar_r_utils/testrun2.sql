drop user fusion cascade;

create user fusion identified by fusion;

grant connect,resource,unlimited tablespace,ctxapp to fusion  identified by fusion;
show user

set timing on

alter session set current_schema = ctxsys;

@ctxdiag.sql

connect fusion/fusion

drop table ctx_tab purge;

create table ctx_tab (
  id   number,
  doc  varchar2(100));

declare
  i number;
begin
  for i in 1..330333 loop
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

exec ctx_diag.k_to_r('dr$ctx_ind$k', 'dr$ctx_ind$r');
