--
-- This procedure loads all existing plans as disabled SQL plan baselines
-- and then adds a new enabled SQL plan baseline for the plan we want.
--
create or replace procedure add_my_plan (for_sqlid varchar2, new_plan_sqlid varchar2, new_phv number) as
  num   pls_integer;
  sqlh  varchar2(100);
  v_sql_text clob;

  cursor existing_spb_handle is
     select distinct b.sql_handle
     from   dba_sql_plan_baselines b,
            sys.v_$sqlarea         s
     where  s.exact_matching_signature = b.signature
     and    s.sql_id                   = for_sqlid; 

  cursor new_spb is
     select b.sql_handle,
            b.plan_name
     from   dba_sql_plan_baselines b,
            sys.v_$sqlarea         s
     where  s.exact_matching_signature = b.signature
     and    s.sql_id                   = for_sqlid
     and    b.enabled = 'YES'; 

   cursor sql_txt is
      select replace(sql_fulltext, chr(00), ' ')
      into v_sql_text
      from v$sqlarea
      where sql_id = trim(for_sqlid)
      and rownum = 1;
begin
  --
  -- Drop any existing SPBs for our SQL statement
  --
  open existing_spb_handle;
  fetch existing_spb_handle into sqlh;
  if existing_spb_handle%FOUND
  then
     num    := dbms_spm.drop_sql_plan_baseline(sql_handle=>sqlh);
     dbms_output.put_line('Dropped '||num||' existing SPBs for SQLID '||for_sqlid);
  else
     dbms_output.put_line('No existing SQL plan baselines to drop');
  end if;
  close existing_spb_handle;
  --
  -- Load all plans for SQL statement with ENABLED=>'NO'
  --
  num := dbms_spm.load_plans_from_cursor_cache(sql_id=>for_sqlid, enabled=>'NO');
  --
  -- Get the SPB SQL Handle
  --
  open existing_spb_handle;
  fetch existing_spb_handle into sqlh;
  if existing_spb_handle%NOTFOUND
  then
     raise_application_error(-20001, 'Something went wrong - no SPB has been loaded');
  end if;
  close existing_spb_handle;
  --
  dbms_output.put_line('Created '||num||' disabled SPBs for SQLID '||for_sqlid);
  --
  -- Load the plan we want into an enabled SPB
  -- Default is enabled=>YES
  -- 
  open sql_txt;
  fetch sql_txt into v_sql_text;
  close sql_txt;
  num := dbms_spm.load_plans_from_cursor_cache (
                    sql_id          => new_plan_sqlid,
                    plan_hash_value => new_phv,
                    sql_text        => v_sql_text);
  --
  -- Report back what we have to confirm
  --
  for spb in new_spb
  loop
     dbms_output.put_line('Enabled SPB - Name: '||spb.plan_name||' SQL handle: '||sqlh);
  end loop;
end;
/
show errors 
