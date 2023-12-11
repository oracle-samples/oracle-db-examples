set echo on
--
-- where the files will be found
--
define LOCATION = /mnt/raford/Documents

conn / as sysdba

--
-- two users: "table_owner" - owns the table and index.
--            "normal_user"   - will get basic privs on the table
--

exec begin execute immediate 'drop user table_owner cascade'; exception when others then null; end;
grant connect,resource,ctxapp,unlimited tablespace to table_owner identified by table_owner;
exec begin execute immediate 'drop user normal_user cascade'; exception when others then null; end;
create user normal_user identified by normal_user;
grant create session to normal_user;
exec begin execute immediate 'drop role CAN_USE_FILESTORE_INDEX'; exception when others then null; end;

--
-- role: CAN_USE_FILESTORE_INDEX for the file access privs
--
create role CAN_USE_FILESTORE_INDEX;
exec ctxsys.ctx_adm.set_parameter('FILE_ACCESS_ROLE', 'CAN_USE_FILESTORE_INDEX')
grant CAN_USE_FILESTORE_INDEX to table_owner;
grant CAN_USE_FILESTORE_INDEX to normal_user;
--
-- create our preferences, table and index
-- preference: TABLE1_FILE_DATASTORE
--

conn table_owner/table_owner

begin
  begin ctx_ddl.drop_preference('TABLE1_FILE_DATASTORE '); exception when others then null; end;
  ctx_ddl.create_preference('TABLE1_FILE_DATASTORE ', 'FILE_DATASTORE');
  ctx_ddl.set_attribute('TABLE1_FILE_DATASTORE ', 'PATH', '&&LOCATION');
end;
/

exec begin execute immediate 'drop table table1 purge'; exception when others then null; end;
create table table1(filename varchar2(20));
CREATE INDEX CTX_RR_TABLE1 ON TABLE1 (FILENAME) 
INDEXTYPE IS "CTXSYS"."CONTEXT" PARAMETERS ('datastore TABLE1_FILE_DATASTORE sync (on commit)');

--
-- add a row as index owner, sync on commit works fine
--

INSERT INTO TABLE1(FILENAME) VALUES('junk.txt');
COMMIT;

SELECT FILENAME FROM TABLE1 WHERE CONTAINS(FILENAME, 'junk',1) > 0;

--
-- now we'll repeat as a different user
--

grant select, insert, update, delete on table1 to normal_user;

conn normal_user/normal_user

--
-- query to existing rows works fine
--

SELECT FILENAME FROM table_owner.TABLE1 WHERE CONTAINS(FILENAME, 'junk',1) > 0;

--
-- but new rows are not added to index
--

INSERT INTO table_owner.TABLE1(FILENAME) VALUES('connor.txt');
COMMIT;
SELECT FILENAME FROM table_owner.TABLE1 WHERE CONTAINS(FILENAME, 'connor',1) > 0;

--
-- I have to issue an explicit sync to see them
--

conn table_owner/table_owner
SELECT FILENAME FROM table_owner.TABLE1 WHERE CONTAINS(FILENAME, 'connor',1) > 0;
exec ctx_ddl.sync_index('CTX_RR_TABLE1')
SELECT FILENAME FROM table_owner.TABLE1 WHERE CONTAINS(FILENAME, 'connor',1) > 0;

--
-- I thought it might be the file access role being needed...but it wasnt
--

conn / as sysdba
grant CAN_USE_FILESTORE_INDEX to normal_user;

conn normal_user/normal_user

INSERT INTO table_owner.TABLE1(FILENAME) VALUES('oracle.txt');
COMMIT;

SELECT FILENAME FROM table_owner.TABLE1 WHERE CONTAINS(FILENAME, 'oracle',1) > 0;

