-- Procedure to safely truncate DR$UNINDEXED table
-- truncates DR$UNINDEXED table when there are still rows in it for a specific index

-- Run the procedure as follows logged in as SYS
--    alter session set current_schema = CTXSYS
--    set serveroutput on
--    @force_trunc_drunindexed.sql
--    execute force_trunc_drunindexed(retries => 10[,index_id => NNN[,part_id = YYY]])
---   see end for examples

-- This procedure runs as user SYS
-- If connect / as sysdba does not work on your system, update the connect line below as appropriate.

connect / as sysdba

alter session set current_schema = CTXSYS;

set serveroutput on size 100000

create or replace procedure force_trunc_drunindexed (
     index_id  integer default 0,
     part_id   integer default 0,
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
        -- now check the table is empty except for the expected index
        select count(*) into rowcount from ctxsys.dr$unindexed 
        where (index_id = 0 or (unx_idx_id != index_id) )
          and (part_id  = 0 or (unx_ixp_id != part_id ) );

        if rowcount = 0 then
           -- it's otherwise empty, we can truncate it
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

end force_trunc_drunindexed;
/
-- list 
show errors

-- Run the procedure as follows, logged in as SYS

-- alter session set current_schema = CTXSYS;
-- set serveroutput on
-- execute force_trunc_drunindexed(retries => 10)  /* all rows */
-- or
-- execute force_trunc_drunindexed(retries => 10, index_id = 1180 ) 
--    that ignores rows for index 1180 (from ctx_user_indexes.idx_id)
-- or 
-- execute force_trunc_drunindexed(retries => 10, index_id = 1180, part_id => 123) 
--    that ignore rows for index 1180, partition id 123 
--    (from ctx_user_indexes.idx_id and ctx_user_index_partitions.ixp_id)
-- -- when done you can delete the procedure if you wish:
-- drop procedure force_trunc_drunindexed;

