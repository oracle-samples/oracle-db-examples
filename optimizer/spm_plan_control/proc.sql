create or replace procedure set_my_plan (for_sqlid varchar2, new_plan_sqlid varchar2, new_phv number) as
  num   pls_integer;
  sqlh  varchar2(100);

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
begin
  --
  -- Drop any existing SPBs for our SQL statement
  -- You may or may not wish to do this
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
  -- We need to check that we have captured at least one SQL plan baseline
  -- because we will replace it with the plan we want
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
  dbms_output.put_line('Associating plan SQLID/PHV '||
                            new_plan_sqlid||'/'||new_phv||' with SPB SQL Handle '||sqlh);
  --
  -- Load the plan we want into an enabled SPB
  -- Default is enabled=>YES
  -- 
  num := dbms_spm.load_plans_from_cursor_cache(sql_id=>new_plan_sqlid, 
                                                             plan_hash_value=>new_phv, sql_handle=>sqlh);
  --
  -- Report back what we have to confirm
  --
  for spb in new_spb
  loop
     dbms_output.put_line('Enabled SPB - Name: '||spb.plan_name||' SQL handle: '||spb.sql_handle);
  end loop;
end;
/
show errors 
