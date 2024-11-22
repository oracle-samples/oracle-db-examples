-- Procedure to safely truncate DR$UNINDEXED table
-- Checks that there are no committed or uncommitted rows in DR$UNINDEXED, then locks table and truncates it

-- Run the procedure as follows, logged in as ctxsys
--    set serveroutput on
--    @truncate_drunindexed.sql
--    execute truncate_drunindexed(retries => 10)

-- This procedure runs as user CTXSYS, so that user must be unlocked
-- CHANGE SYSTEM PASSWORD in line below
-- it is strongly recommended to change the CTXSYS password in the "alter user" and "connect" statements as well

connect system/oracle

alter user ctxsys identified by oracle account unlock;

connect ctxsys/oracle

set serveroutput on size 100000

create or replace procedure truncate_drunindexed (
     retries integer default 10
) is
   sleep_secs  integer := 2;   -- two second sleep between retries. Adjust if required.
   rowcount    integer := -1;
   retry_count integer := 0;
   success     boolean := false;

   resource_busy exception;
   pragma exception_init (resource_busy, -54);

begin

   while rowcount != 0 and retry_count <= retries loop

     retry_count := retry_count + 1;

     begin

        -- if table lock fails this will be picked up by exception handler
        lock table ctxsys.dr$unindexed in exclusive mode nowait;
        -- now check the table is empty
        select count(*) into rowcount from ctxsys.dr$unindexed;

        if rowcount = 0 then
           -- it's empty, we can truncate it
           execute immediate ('truncate table ctxsys.dr$unindexed');
           success := true;
           exit;   -- exit from loop
        end if;

        -- if still in loop, then we foudn some rows in the table
        dbms_output.put_line('Fail ' || retry_count || ' - rows found in DR$UNINDEXED table. Wait and retry.');
        commit;  -- release lock
        dbms_lock.sleep(sleep_secs);

     exception 
     when resource_busy then 
        -- table lock failed, some process has uncommitted rows in it
        dbms_output.put_line('Fail ' || retry_count || ' - table is locked. Wait and retry.');
        dbms_lock.sleep(sleep_secs);
     when others then 
        -- something else went wrong. Abort.
        dbms_output.put_line('Unexpected exception: '|| SQLERRM);
        exit;
     end;

  end loop;

  if success then
     commit;  -- shouldn't really be necessary
     dbms_output.put_line ('Succeeded in truncating DR$UNINDEXED table');
  else
     commit;  -- release lock if present
     dbms_output.put_line ('Failed to truncate DR$UNINDEXED table');
  end if;

end truncate_drunindexed;
/
-- list 
show errors

-- Run the procedure as follows, logged in as ctxsys

-- set serveroutput on
-- execute truncate_drunindexed(retries => 10)

-- Don't forget to re-lock the CTXSYS account when done:
-- alter use ctxsys account lock;
