-- Procedure to safely truncate DR$UNINDEXED table
-- Checks that there are no committed or uncommitted rows in DR$UNINDEXED, then locks table and truncates it

-- This procedure runs as user CTXSYS, so that user must be unlocked

connect system/welcome1

alter session set current_schema = CTXSYS

set serverout on size 100000

create or replace procedure truncate_drunindexed (
     retries integer default 10
) is
   sleep_secs  integer := 2;
   rowcount    integer := -1;
   retry_count integer := 0;
   success     boolean := false;

   resource_busy exception;
   pragma exception_init (resource_busy, -54);

begin

   while rowcount != 0 and retry_count <= retries loop

     retry_count := retry_count + 1;

     begin

        lock table ctxsys.dr$unindexed in exclusive mode nowait;
        select count(*) into rowcount from ctxsys.dr$unindexed;

        if rowcount = 0 then
           execute immediate ('truncate table ctxsys.dr$unindexed');
           success := true;
           exit;
        end if;

        dbms_output.put_line('Fail ' || retry_count || ' - rows found in DR$UNINDEXED table. Wait and retry.');
        commit;  -- release lock
        dbms_lock.sleep(sleep_secs);

     exception 
     when resource_busy then 
        dbms_output.put_line('Fail ' || retry_count || ' - table is locked. Wait and retry.');
        dbms_lock.sleep(sleep_secs);
     when others then 
        dbms_output.put_line('Unexpected exception: '|| SQLERRM);
        exit;
     end;

  end loop;

  if success then
     commit;
     dbms_output.put_line ('Succeeded in truncating DR$UNINDEXED table');
  else
     commit;
     dbms_output.put_line ('Failed to truncate DR$UNINDEXED table');
  end if;

end truncate_drunindexed;
/
-- list 
show errors

-- Run the procedure as follows, logged in as ctxsys
-- execute truncate_drunindexed(10)

-- Don't forget to re-lock the CTXSYS account when done:
-- alter use ctxsys account lock;
