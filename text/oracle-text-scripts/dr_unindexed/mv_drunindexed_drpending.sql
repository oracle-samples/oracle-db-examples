-- Procedure to move rows for a particular index from DR$UNINDEXED to DR$PENDING,
-- then safely truncate DR$UNINDEXED table
-- truncates DR$UNINDEXED table when there are still rows in it for a specific index

-- Run the procedure as follows logged in as SYS
--    alter session set current_schema = CTXSYS
--    set serveroutput on
--    @mv_drunindexed_drpending.sql
--    execute mv_drunindexed_drpending(retries => 10[,index_id => NNN[,part_id = YYY]])
---   see end for examples

-- This procedure runs as user SYS
-- If connect / as sysdba does not work on your system, update the connect line below as appropriate.

connect / as sysdba

alter session set current_schema = CTXSYS;

set serveroutput on size 100000

create or replace procedure mv_drunindexed_drpending (
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
           -- it's otherwise empty, we can continue

           -- check no rows in DR$PENDING for our index
           select count(*) into rowcount from ctxsys.dr$pending where pnd_cid = index_id and pnd_pid = part_id;
           if rowcount > 0 then
              dbms_output.put_line('Index ID '|| index_id ||' (partition '|| part_id ||') has unsynced rows. Run CTX_DDL.SYNC_INDEX(''indexname'') before proceeding');
              exit;
           end if;

           -- first we copy the rows for our specified index to the pending table. Note we will NOT move them if already in DR$PENDING

           insert into ctxsys.dr$pending (pnd_cid, pnd_pid, pnd_rowid, pnd_timestamp, pnd_lock_failed)
           select unx_idx_id, unx_ixp_id, unx_rowid, sysdate, 'N'
           from ctxsys.dr$unindexed
           where unx_idx_id = index_id
           and   unx_ixp_id = part_id;

           dbms_output.put_line(to_char(sql%rowcount)||' rows moved from UNINDEXED to PENDING for index '||index_id||' partition '||part_id);

           -- now truncate the unindexed table
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
     commit;  -- shouldn't really be necessary - truncate does implicit COMMIT
     dbms_output.put_line ('Succeeded in truncating DR$UNINDEXED table');
  else
     commit;  -- release lock if present
     dbms_output.put_line ('Failed to truncate DR$UNINDEXED table');
  end if;

end mv_drunindexed_drpending;
/
-- list 
show errors

-- Run the procedure as follows, logged in as SYS

-- alter session set current_schema = CTXSYS;
-- set serveroutput on
-- execute mv_drunindexed_drpending(retries => 10)  /* all rows */
-- or
-- execute mv_drunindexed_drpending(retries => 10, index_id = 1180 ) 
--    that ignores rows for index 1180 (from ctx_user_indexes.idx_id)
-- or 
-- execute mv_drunindexed_drpending(retries => 10, index_id = 1180, part_id => 123) 
--    that ignore rows for index 1180, partition id 123 
--    (from ctx_user_indexes.idx_id and ctx_user_index_partitions.ixp_id)
-- -- when done you can delete the procedure if you wish:
-- drop procedure mv_drunindexed_drpending;
-- don't forget to sync the index afterwards
