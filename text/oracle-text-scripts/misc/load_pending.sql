-- This procedure loads the DR$PENDING table with all the rowids for a partitioned Oracle Text index
-- it is designed for benchmarking SYNC INDEX
-- it allows you to to create a NOPOPULATE index on an already-loaded table, then insert all the values necessary
-- for a sync.  
-- This way you can load the table without having a text index present on it, which makes the loads much faster

-- NOTES:   ONLY WORKS FOR A PARTITIONED INDEX
-- NOTES:   DIRECT INSERTS TO DR$PENDING ARE NOT SUPPORTED - THIS IS FOR TESTING ONLY
-- NOTES:   THE CALLER OF THIS ROUTINE MUST BE THE INDEX OWNER AND MUST HAVE _EXPLICIT_ INSERT ACCESS TO DR$PENDING

create or replace procedure load_pending (index_name varchar2) is
   v_idx_id  number;
   v_tab_name varchar2(30);
   sqltext varchar2(256);
begin

   select idx_id, idx_table into v_idx_id, v_tab_name 
   from ctx_user_indexes where idx_name = upper(index_name);

   for c in ( 
          select ixp_id, ixp_index_partition_name
          from ctx_user_index_partitions 
          where ixp_index_name = upper(index_name) 
            ) loop
      sqltext := 'insert into ctxsys.dr$pending select '||v_idx_id||', '||c.ixp_id||', rowid, current_timestamp, ''N'' from '||
              v_tab_name||' partition ('||c.ixp_index_partition_name||')';

      --dbms_output.put_line(sqltext);
      execute immediate (sqltext);

   end loop;

end;
/
list
show errors

-- call it like this.  Truncate is unnecessary if index is newly created
-- dr$pending is a shared table, make sure it's not being used by other indexes before truncating it.

--truncate table ctxsys.dr$pending;
--exec load_pending('mydocs_index')
