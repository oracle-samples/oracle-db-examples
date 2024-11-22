-- Patch up all $I, $G and $P tables for long tokens
-- script must be run as SYS user

alter session set current_schema=ctxsys;

@?/ctx/admin/ctxpreup.sql

--Loop over all indexes and widen token columns (Runs as sys, in CTXSYS schema)
DECLARE
     table_name VARCHAR2(128);
     event_level NUMBER;
BEGIN

 FOR r_index_partitions IN
       (SELECT i.idx_owner,
               i.idx_id,
               i.idx_name,
               i.idx_type,
               ixp.ixp_id,
               ixp.ixp_index_partition_name
        FROM CTX_INDEXES i LEFT OUTER JOIN
             CTX_INDEX_PARTITIONS ixp
             ON ixp.ixp_index_name = i.idx_name
        WHERE i.idx_status LIKE 'INDEXED'
          AND (i.idx_type LIKE 'CONTEXT'
          OR i.idx_type LIKE 'CONTEXT2')
        ORDER BY i.idx_id, ixp.ixp_id) LOOP
  BEGIN
 --dbms_output.put_line('Index ' ||  r_index_partitions.idx_owner || '.'
 --|| r_index_partitions.idx_name || ': ' ||r_index_partitions.ixp_id);
   BEGIN
    -- Widening $I table --
   table_name := dr$temp_get_object_name(r_index_partitions.idx_owner,
                                         r_index_partitions.idx_name,
                                         r_index_partitions.idx_id,
                                         r_index_partitions.ixp_id,
                                         'I');
                                                                           
         
  dbms_output.put_line('Table Name ' ||  table_name);                         
                                                                

  execute immediate('alter table ' || table_name ||
  	                ' modify TOKEN_TEXT VARCHAR2(255)');
  EXCEPTION
   when others then
    if (SQLCODE = -00942) then --Table Does Not Exist!
     dbms_output.put_line('Table ' ||  table_name || 
     	                  ' not be found. Skipping.');
     null;
    else
     raise;
    end if;
  END;
      
   -- Widening $P table --
   BEGIN    
        table_name := dr$temp_get_object_name(r_index_partitions.idx_owner,
                                              r_index_partitions.idx_name,
                                              r_index_partitions.idx_id,
                                              r_index_partitions.ixp_id,
                                              'P');
                                                                              
         
    dbms_output.put_line('Table Name ' || table_name);

   
    sys.dbms_system.read_ev(30579,event_level);       
                        
    if(bitand(event_level, 2097152) = 0) 
       then        
        execute immediate(
         'alter table ' || table_name ||
         ' modify (pat_part1 VARCHAR2(252), pat_part2 VARCHAR2(255))');
    else 
        execute immediate(
         'alter table ' || table_name ||
         ' modify (pat_part1 VARCHAR2(255), pat_part2 VARCHAR2(255))');
    end if;

  EXCEPTION
   when others then
    if (SQLCODE = -00942) then --Table Does Not Exist!
     dbms_output.put_line('Table ' ||  table_name || 
     	                  ' not be found. Skipping.');
     null;
    else
     raise;
    end if;         
  END;
      
      -- Widening $G table --
  BEGIN    
    table_name := dr$temp_get_object_name(r_index_partitions.idx_owner,
                                          r_index_partitions.idx_name,
                                          r_index_partitions.idx_id,
                                          r_index_partitions.ixp_id,
                                          'G');                       

   dbms_output.put_line('Table Name ' ||  table_name);                        
                                                                 
   
   execute immediate('alter table ' || table_name ||
                     ' modify TOKEN_TEXT VARCHAR2(255)');
        
  EXCEPTION
    when others then
     if (SQLCODE = -00942) then --Table Does Not Exist!
      dbms_output.put_line('Table ' ||  table_name || 
     	                  ' not be found. Skipping.');
      null;
     else
      raise;
     end if;         
  END;
      
-----------------------
   END;

 END LOOP;

END;
/
show errors;

@?/ctx/admin/ctxposup.sql
