-- This package converts a conventional non-small-r index into a 35K 
-- small R index by copying the $R table to a new version with smaller rows
-- and updating the text data dictionary appropriately.

-- BASICS:
--   Please read the full notes below, but basically this script needs to be
--   loaded into the SYS schema, then an index can be upgraded by calling:
--      small_r_convert.convert_index('<indexowner>', '<indexname>')
--
-- Notes:
--
--   SECURITY:
--   This procedure must be compiled and run by the SYS user
--   While efforts have been taken to avoid SQL injection, it has not been exhaustively
--   tested. In particular the use of a rogue R_TABLE_CLAUSE might pose a risk.
--   Therefore the procedure should not be made available to users other than SYS.
--   If the SYS user is not available, it is up to the user to modify the code (remove
--   the SYS user check at the start) and ascertain the necessary privileges to run
--   the procedure.
--   
--   USAGE:
--   Load this file into the SYS schema. For example:
--      connect / as sysdba
--      @small_r_conversion3.sql
--   To check that your system configuration is correct, run the check_readiness
--   function. This will return the string "OK" if the system is ready for conversion,
--   or will report an exception with information if not. For example, in SQL*Plus
--   you could do:
--      connect / as sysdba
--      variable t varchar2(10);
--      exec :t := small_r_convert.check_readiness
--      print t
--   (Note: check_readiness creates a text table in the SYS schema with 80,000 
--   small rows and indexes it, so may take a minute or two to run. 
--   It should clean up the table and index after completion).
--
--   If that succeeds without error you are ready to proceed.
--   Ensure that the index is question is NOT undergoing any DML or queries on
--   the indexed table. (Running this script while DML is occurring may potentially
--   result in lost information. Queries may return errors including ORA-0600 erors).
--   As SYS user, in SQL*Plus run:
--      execute sys.small_r_convert.convert_index( ownername, indexname)
--        eg.
--      execute sys.small_r_convert.convert_index( 'roger', 'myindex' )
--   *********************************************************************************
--   * After running, the original $R table will have been copied to DR$indexname$RO *
--   * Once query testing is complete, that table should be dropped.                 *
--   *********************************************************************************
--   This procedure is re-runnable. If it detects the index is already using SMALL_R_ROW
--   it will simply exit.
--     ** NOTE : this version will continue even if SMALL_R_ROW is set in the data dictionary
--     ** in order to fix problems caused by 11.2 -> 12.1 upgrades
--   If it fails, investigations should be made as
--   to why, and if necessary the DR$indexname$RO table should be renamed back to 
--   DR$indexname$R. The DRC constraint will need to be reinstated using the SQL:
--      alter table DR$indexname$R add constraint DRC$indexname$R primary key (row_no)
--   It may be necessary to drop the "new" table DR$indexname$RN if that has been created.
--   Turning on server output (SET SERVEROUTPUT ON in SQL*Plus) may aid in debugging.
--
--   VERIFICATION:
--   To check that it worked, as the table owner run:
--     select row_no, length(data) from DR$indexname$R order by row_no;
--   You should see several rows of 490000 length (assuming a large enough index)
--   and probably one shorter row at the end. If you have a row (or more than one row) with
--   length longer than 490000, it has not worked.
--   Then verify that queries work correctly. If you get errors like:
--        DRG-10513: index DOCSINDEX metadata is corrupt
--        ORA-30576: ConText Option dictionary loading error
--   something has gone wrong in the dictionary update part
--   If you get errors like:
--        DRG-50857: oracle error in drekmap (reselect rowid row locator)
--        DRG-50858: OCI error: OCI_NO_DATA
--      or just
--        ORA-29903: error in executing ODCIIndexFetch() routine
--        ORA-20000: Oracle Text error:
--   Then the copy of the $R data values has not succeeded
--   In either case you should contact the author of this package, Roger Ford
--
--   LIMITATIONS
--   This procedure will not work for:
--     o Indexnames which exceed 24 characters in length (20 for LOCAL index)
--     o "Exotic" index names such as "My New Indexname"
--     o Environments having the "original" 70K small_r row size
--     o Local indexes having > 9999 partitions
--   Index names using multi-byte characters have not been tested
--
--   VERSION HISTORY
--    Version  By          Date      Description
--    0.8      roger.ford  20170223  Initial released version for internal testing
--    0.9      roger.ford  20170228  Added code for partitioned indexes
--                                   Check db version
--                                   Allow for "missing" constraint in 11.2.0.4
--                                   check_readiness function
--                                   More resilient to restart
--    0.91     roger.ford  20170228  Re-entrant: just exits if already run on 
--                                   this index. Checks for "DBA" user rather 
--                                   than SYS.
--    0.92     roger.ford  20170719  Continues even if SMALL_R_ROW is set in data
--                                   dictionary, to fix issues where SMALL_R_ROW value
--                                   was wrong due to database upgrade
--    0.93     roger.ford  20200217  Increased buffer size to 560 to avoid "too much
--                                   data error" when > 200M rows in base table
--    0.94     roger.ford  20200227  Changed ALTER SYSTEM FLUSH SHARED_POOL to call 
--                                   purgeKGL - works on RAC systems as well
-- If this procedure is to be called by a user other than sys, the user must have
-- the following grants:
--   dba
--   select on v_$instance
--   create any table
--   update any table
--   insert any table
--   alter system

alter session set plsql_warnings='ENABLE:ALL';

create or replace package small_r_convert 
   authid current_user as 
  
   function check_readiness return varchar2;

   procedure convert_index (owner varchar2, indexname varchar2);

end small_r_convert;
/
list
show errors

create or replace package body small_r_convert as

-- cleanup from check_readiness
-- private procedure not callable externally

procedure cleanup is
begin
   execute immediate ('drop table DR$TEST$SMALLRTAB');
   ctx_ddl.drop_preference('dr$test$smallrstor');
end cleanup;

function check_readiness return varchar2 as
   row_count      integer;
   no_tab_or_view exception;
   PRAGMA         exception_init(no_tab_or_view, -942);
   text_error exception;
   PRAGMA         exception_init(text_error, -20000);
begin

   begin
      execute immediate ('drop table DR$TEST$SMALLRTAB');
   exception when no_tab_or_view then null;
   end;

   dbms_output.put_line('creating table DR$TEST$SMALLRTAB');
   execute immediate ('create table DR$TEST$SMALLRTAB (text varchar2(200))');

   -- SMALL_R_ROW $R table will have 35K docs per row
   -- so insert 71K docs:

   dbms_output.put_line('populating table');
   for i in 1..71000 loop
     execute immediate('insert into DR$TEST$SMALLRTAB values (''X'')');
   end loop;

   begin
      ctx_ddl.drop_preference('dr$test$smallrstor');
   exception when text_error then null;
   end;

   ctx_ddl.create_preference('dr$test$smallrstor', 'basic_storage');
   ctx_ddl.set_attribute('dr$test$smallrstor', 'SMALL_R_ROW', 'T');

   -- normally must set event, either at system level or session level
   -- otherwise will get "DRG-11135: feature not generally available"
   -- though this doesn't seem to apply to SYS
   -- For session level, user must have "set event" priv
   -- alter system set events '30579 trace name context forever, level 268435456';
   execute immediate('alter session set events ''30579 trace name context forever, level 268435456''');

   dbms_output.put_line('creating index');
   execute immediate ('create index DR$TEST$SMALLRIND on DR$TEST$SMALLRTAB(text) 
   indextype is ctxsys.context
   parameters (''storage dr$test$smallrstor'')');

   -- should get three rows returned
   execute immediate ('select count(*) from DR$DR$TEST$SMALLRIND$R') into row_count;

   if row_count <= 1 then
      dbms_output.put_line('only 1 $R row created. Cleanup then raise error');
      cleanup;
      raise_application_error(-20000, 'SMALL_R_ROW setting not working on this system');
   end if;

   if row_count = 2 then
      dbms_output.put_line('only 2 $R rows created. Cleanup then raise error');
      cleanup;
      raise_application_error(-20000, 'SMALL_R_ROW uses 70K row size. Install patch 16902031 (35K row size) before attempting conversion');
   end if;

   dbms_output.put_line('3 rows created, $R uses correct row size. Cleaning up temp table and index');

   cleanup;

   return 'OK';

end check_readiness;

procedure convert_index 
   ( owner     varchar2, 
     indexname varchar2) 
   as

vindexname  varchar2(30);
vowner      varchar2(30);
buff        raw(4000);
amount      integer;
offset      integer;
outlob      blob;
ooff        integer;
oamount     integer;
orow        integer;
idxid       integer;
partcnt     integer;
partid      integer;
ssql        varchar2(4000);
type rctype is ref cursor;
ftch_cursor rctype;
part_cursor rctype;
local_lob   blob;
isql        varchar2(4000);
new_table   varchar2(61);
old_table   varchar2(61);
old_table_no_schema varchar2(30);
constraint  varchar2(30);
r_tab_cls   varchar2(4000);
dummy       varchar2(30);
vsn         varchar2(20);
row_count   integer;
ixvvalue    varchar2(20);

no_constraint exception;
PRAGMA      exception_init(no_constraint, -2443);


begin

--   -- check calling user is a DBA
--   select count(*) into row_count from user_role_privs where granted_role = 'DBA';
--   if row_count = 0 then
--      raise_application_error(-20000, 'This procedure must be run as a DBA user');
--   end if;
   
--   -- check version number
--
--   select version into vsn from v$instance;
--
--   if substr(vsn, 1, 8) != '11.2.0.4' and
--      substr(vsn, 1, 8) != '12.1.0.1' and
--      substr(vsn, 1, 8) != '12.1.0.2' then
--      raise_application_error(-20000, 'Database version must be 11.2.0.4, 12.1.0.1 or 12.1.0.2');
--   end if;

   -- checks to avoid SQL injection
   -- we don't support quoted lower-case index names

   if substr(indexname,1,1) = '"' then
      raise_application_error(-20000, 'Quoted index names not currently supported');
   end if;
   if substr(owner,1,1) = '"' then
      raise_application_error(-20000, 'Quoted schema names not currently supported');
   end if;

   dummy := dbms_assert.simple_sql_name(indexname);
   dummy := dbms_assert.simple_sql_name(owner);

   vindexname := upper(indexname);
   vowner     := upper(owner);

   -- can't support indexnames longer than 24 chars because of DR$ indexname $RN

   if length(vindexname) > 24 then
      raise_application_error(-20000, 'Index names longer than 24 chars not currently supported');
   end if;

   -- check index exists and is not partitioned (todo: support partitioned indexes)

   -- check index exists

   begin
      select idx_id into idxid from ctxsys.ctx_indexes where idx_owner = vowner and idx_name = vindexname;
   exception when no_data_found then
      raise_application_error(-20000, 'index '||vowner||'.'||vindexname||' not found');
   end;

   -- all checks passed. Let's get on with it. First create the temporary $R table if it doesn't already exist

   -- fetch the R_TABLE_CLAUSE value

   ssql := '
select ixv_value 
 from 
   ctxsys.dr$index_value,
   ctxsys.dr$object_attribute,
   ctxsys.dr$index,
   ctxsys.dr$object,
   ctxsys.dr$class,
   sys.all_users u
 where ixv_idx_id = idx_id
   and idx_owner# = u.user_id
   and idx_name   = :indexname
   and oat_name   = ''R_TABLE_CLAUSE''
   and oat_cla_id = obj_cla_id
   and oat_obj_id = obj_id
   and cla_system = ''N''
   and oat_cla_id = cla_id
   and ixv_oat_id = oat_id
   and idx_id     = ixv_idx_id
   and u.username = :owner
';

   execute immediate ssql into r_tab_cls using vindexname, vowner;

   -- index exists. Is it partitioned?

   select count(*) into partcnt from ctxsys.ctx_index_partitions 
     where ixp_index_owner = vowner and ixp_index_name = vindexname;

   if partcnt > 9999 then 
      -- can't support > 9999 partitions
      raise_application_error(-20000, 'Only 9999 partitions currently allowed');
   end if;

   if partcnt > 0 then
      -- can't support indexnames longer than 20 chars for partitioned index
      if length(vindexname) > 20 then
         raise_application_error(-20000, 'Partitioned index names longer than 20 chars not currently supported');
      end if;
   end if;

   -- don't continue if already using SMALL_R_ROW

   ssql := 'select ixv_value from ctxsys.ctx_index_values where ixv_index_owner = :owner and ixv_index_name = :indexname and ixv_attribute = ''SMALL_R_ROW''';
   begin
      execute immediate ssql into ixvvalue using vowner, vindexname;
   exception when NO_DATA_FOUND then
      ixvvalue := 'NO';
   end;
   if ixvvalue = 'YES' then
      -- already done, nothing to do
      dbms_output.put_line('Index already uses SMALL_R_ROW setting');
      -- return;
   end if;

   -- check for leftover "old table" and don't proceed if it exists

   ssql := 'select count(*) from all_tables where owner = :owner and table_name like :oldtable';

   if partcnt > 0 then
      execute immediate ssql into row_count using vowner, 'DR#' || vindexname || '%' || '$RO';
      if row_count > 0 then
         raise_application_error(-20000, 'Previous $R table '||vowner||'.'||'DR#'|| vindexname || 'nnnn$RO found. Drop before proceeding if not needed');
      end if;
   else
      execute immediate ssql into row_count using vowner, 'DR$' || vindexname || '$RO';
      if row_count > 0 then
         raise_application_error(-20000, 'Previous $R table '||vowner||'.'||'DR$' || vindexname || '$RO' || ' found. Drop before proceeding if not needed');
      end if;
   end if;

   -- if partitioned, we need to loop through each $r table
   -- if not partitioned, we create a dummy loop with SQL which returns a single value -1 as a
   --   flag for a non-partitioned index

   if partcnt > 0 then
      ssql := 'select ixp_id from ctxsys.ctx_index_partitions 
              where ixp_index_owner = :owner and ixp_index_name = :indexname';
   else
      ssql := 'select -1 from dual where 1=1 or :1 = :2';
   end if;

   open part_cursor for ssql using vowner, vindexname;

   fetch part_cursor into partid;
 
   while not part_cursor%NOTFOUND loop

      if partid = -1 then 
         new_table := vowner || '.DR$' || vindexname || '$RN';
         old_table := vowner || '.DR$' || vindexname || '$R';
         old_table_no_schema  := 'DR$' || vindexname || '$R';
         constraint          := 'DRC$' || vindexname || '$R';
      else
         new_table := vowner || '.DR#' || vindexname || lpad(partid, 4, '0') || '$RN';
         old_table := vowner || '.DR#' || vindexname || lpad(partid, 4, '0') || '$R';
         old_table_no_schema  := 'DR#' || vindexname || lpad(partid, 4, '0') || '$R';
         constraint          := 'DRC#' || vindexname || lpad(partid, 4, '0') || '$R';
      end if;

      -- create the new $r table

      ssql := 'create table '||new_table||' (row_no number(5), data blob) '||
         r_tab_cls;

      dbms_output.put_line('Execute: '||ssql);
      execute immediate ssql;

      ooff    := 1;
      oamount := 0;
      orow    := 0;

      dbms_lob.createtemporary(outlob, true);

      ssql := 'select data from '|| old_table || ' order by row_no';
      isql := 'insert into '|| new_table || ' (row_no, data) values(:orow, :outlob)';

      dbms_output.put_line('ssql: '||ssql);
      dbms_output.put_line('isql: '||isql);

      dbms_output.put_line('start copying $R table '||old_table);

      open ftch_cursor for ssql;

      fetch ftch_cursor into local_lob;
      while not ftch_cursor%NOTFOUND loop

         -- dbms_output.put_line('Fetched row');
         if ftch_cursor%NOTFOUND then
            amount := 0;
            continue;
         end if;
        
         offset := 1;
         amount := 560;
         while (amount = 560) loop
            begin
               dbms_lob.read(local_lob, amount, offset, buff);
               -- dbms_output.put_line('read amount:'||amount||' offset: ' || offset);
               offset := offset + amount;
            exception 
               when no_data_found then
                  dbms_output.put_line('no data found during read');
                  amount := 0;
                  continue;
            end;

            -- at this point we've read up to 560 bytes of data which needs to be
            -- written to the current (or new) LOB buffer

            oamount := amount;

            -- dbms_output.put_line('write oamount: '||oamount||' ooff:' || ooff);

            dbms_lob.write(outlob, oamount, ooff, buff);
            ooff := ooff + oamount;
     
            -- if row is full then write to table

            if (ooff > (35000*14)+1) then
               dbms_output.put_line('*** ERROR - too much data: '|| ooff|| ' ***');
               raise_application_error(-20000, 'too much data to write');
            end if;

            if (ooff-1 = (35000*14)) then 
               execute immediate isql using orow, outlob;
               dbms_output.put_line('Writing row '|| orow);
               orow := orow + 1;
               dbms_lob.trim(outlob, 0);
               ooff := 1;
            end if;
           
         end loop;

         fetch ftch_cursor into local_lob;

      end loop;

      close ftch_cursor;

      if dbms_lob.getlength(outlob) > 0 then
         execute immediate isql using orow, outlob;
         dbms_output.put_line('Writing final row '|| orow);
         orow := orow + 1;
      end if;

      dbms_output.put_line('Copy complete for table '|| old_table);

      -- New table is written. Rename tables (keeping old one) and update data dict

      -- rename old table
      ssql := 'alter table '||old_table||' rename to '||old_table_no_schema||'o';
      dbms_output.put_line('Execute: '||ssql);
      execute immediate ssql;

      -- drop the old constraint. If we rename it it leaves an index with the old name that 
      -- prevents us from creating a new one 
      ssql := 'alter table '||old_table||'o drop constraint '||constraint;
  
      dbms_output.put_line('Execute: '||ssql);
      begin
         execute immediate ssql;
      exception
         when no_constraint then
            dbms_output.put_line('*** WARNING: existing constaint '||constraint||' not found (expected in 11.2.0.*)');
      end;

      --rename new table
      ssql := 'alter table '||new_table||' rename to '||old_table_no_schema;
      dbms_output.put_line('Execute: '||ssql);
      execute immediate ssql;

      -- need to create DRC constraint
      ssql := 'alter table '||old_table||' add constraint '||constraint||' primary key (row_no)';
      dbms_output.put_line('Execute: '||ssql);
      execute immediate ssql;

      -- all tables done for this partition

      fetch part_cursor into partid;

   end loop;

   -- update text data dictionary
   -- but only if value not already set for this index

   ssql := 'select count(*) from ctxsys.ctx_index_values where ixv_index_owner = :owner and ixv_index_name = :indexname and ixv_attribute = ''SMALL_R_ROW''';
   execute immediate ssql into row_count using vowner, vindexname;

   if row_count = 0 then
      -- need to do an insert, and update the ixo_cnt in dr$index_object
      ssql := '
insert into ctxsys.dr$index_value (
  ixv_idx_id,
  ixv_oat_id,
  ixv_value,
  ixv_sub_group,
  ixv_sub_oat_id )
  select 
    idx_id, 
    oat_id,
    1,
    0,
    0 
 from 
   ctxsys.dr$object_attribute,
   ctxsys.dr$index,
   ctxsys.dr$object,
   ctxsys.dr$class,
   sys.all_users u
 where 
       idx_owner# = u.user_id
   and idx_name   = :indexname
   and oat_name   = ''SMALL_R_ROW''
   and oat_cla_id = obj_cla_id
   and oat_obj_id = obj_id
   and cla_system = ''N''
   and oat_cla_id = cla_id
   and u.username = :owner';
   dbms_output.put_line('Execute: '||ssql);
   execute immediate(ssql) using vindexname, vowner;
      if SQL%ROWCOUNT != 1 then
         rollback;
         raise_application_error(-20000, 'Error - failed to insert small_r_row setting to data dictionary');
      end if;
      dbms_output.put_line(to_char(SQL%ROWCOUNT)|| ' row inserted');

      ssql := '
update ctxsys.dr$index_object set ixo_acnt = ixo_acnt + 1
   where 
   ( ixo_idx_id, ixo_cla_id, ixo_obj_id ) = 
   ( select 
       idx_id, oat_cla_id, oat_obj_id 
     from 
       ctxsys.dr$object_attribute,
       ctxsys.dr$index,
       ctxsys.dr$object,
       ctxsys.dr$class,
       sys.all_users u
   where 
       idx_owner# = u.user_id
     and idx_name   = :indexname
     and oat_name   = ''SMALL_R_ROW''
     and oat_cla_id = obj_cla_id
     and oat_obj_id = obj_id
     and cla_system = ''N''
     and oat_cla_id = cla_id
     and u.username = :owner
   )';
      dbms_output.put_line('Execute: '||ssql);
      execute immediate(ssql) using vindexname, vowner;
      if SQL%ROWCOUNT != 1 then
         rollback;
         raise_application_error(-20000, 'Error - failed to update count in data dictionary');
      end if;
      dbms_output.put_line(to_char(SQL%ROWCOUNT)|| ' row updated');

   elsif row_count = 1 then
      -- need to do an update of existing value
      ssql := '
update ctxsys.dr$index_value 
set ixv_value = 1 
where (ixv_idx_id, ixv_oat_id) = (
  select 
    idx_id, 
    oat_id
 from 
   ctxsys.dr$object_attribute,
   ctxsys.dr$index,
   ctxsys.dr$object,
   ctxsys.dr$class,
   sys.all_users u
 where 
       idx_owner# = u.user_id 
   and idx_name   = :indexname
   and oat_name   = ''SMALL_R_ROW''
   and oat_cla_id = obj_cla_id
   and oat_obj_id = obj_id
   and cla_system = ''N''
   and oat_cla_id = cla_id
   and u.username = :owner)';
   dbms_output.put_line('Execute: '||ssql);
   execute immediate(ssql) using vindexname, vowner;
      if SQL%ROWCOUNT != 1 then
         rollback;
         raise_application_error(-20000, 'Error - failed to update small_r_row setting to data dictionary (' || to_char(SQL%ROWCOUNT) || ' rows updated - expected 1)');
      end if;
      dbms_output.put_line(to_char(SQL%ROWCOUNT)|| ' row inserted');

   else
      -- this shouldn't happen
      raise_application_error(-20000, 'Wrong number of rows returned from ctx_index_values: expected 0 or 1, got '||to_char(row_count));
   end if;   

   -- next line not strictly necessary as it should already be set, but just in case somebody changes something...
   select idx_id into idxid from ctxsys.ctx_indexes where idx_owner = vowner and idx_name = vindexname;

   ctxsys.drixmd.purgeKGL (
                   p_idxid    => idxid,
                   owner      => vowner,
                   index_name => vindexname,
                   other_name => NULL );

   commit;
   dbms_output.put_line('Committed');

    -- all done. User must delete renamed old table manually

end convert_index;

end small_r_convert;
/
list
show errors

grant execute on small_r_convert to public;
