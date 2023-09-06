-- this uses the old (12.1 and earlier?) method of restricting
-- access to file_datastore, using CTX_ADM.SET_PARAMETER with a parameter 
-- name of FILE_ACCESS_ROLE.
--
-- Later versions use a specific role, TEXT DATASTORE ACCESS
--
-- where the files will be found
--
define LOCATION = c:\Docs

conn / as sysdba

--
-- two users: "dba_text_user" - owns the table and index.
--            "normal_user"   - will get basic privs on the table
--

exec begin execute immediate 'drop user dba_text_user cascade'; exception when others then null; end;
grant dba to dba_text_user identified by dba_text_user;
exec begin execute immediate 'drop user normal_user cascade'; exception when others then null; end;
create user normal_user identified by normal_user;
grant create session to normal_user;
exec begin execute immediate 'drop role CAN_USE_FILESTORE_INDEX'; exception when others then null; end;

--
-- role: CAN_USE_FILESTORE_INDEX for the file access privs
--
create role CAN_USE_FILESTORE_INDEX;
exec ctxsys.ctx_adm.set_parameter('FILE_ACCESS_ROLE', 'CAN_USE_FILESTORE_INDEX')
grant CAN_USE_FILESTORE_INDEX to dba_text_user;

--
-- create our preferences, table and index
-- preference: TABLE1_FILE_DATASTORE
--

conn dba_text_user/dba_text_user

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

SELECT FILENAME FROM dba_text_user.TABLE1 WHERE CONTAINS(FILENAME, 'junk',1) > 0;

--
-- but new rows are not added to index
--

INSERT INTO dba_text_user.TABLE1(FILENAME) VALUES('connor.txt');
COMMIT;
SELECT FILENAME FROM dba_text_user.TABLE1 WHERE CONTAINS(FILENAME, 'connor',1) > 0;

--
-- I have to issue an explicit sync to see them
--

conn dba_text_user/dba_text_user
SELECT FILENAME FROM dba_text_user.TABLE1 WHERE CONTAINS(FILENAME, 'connor',1) > 0;
exec ctx_ddl.sync_index('CTX_RR_TABLE1')
SELECT FILENAME FROM dba_text_user.TABLE1 WHERE CONTAINS(FILENAME, 'connor',1) > 0;

--
-- I thought it might be the file access role being needed...but it wasnt
--

-- grant CAN_USE_FILESTORE_INDEX to normal_user;

conn normal_user/normal_user

INSERT INTO dba_text_user.TABLE1(FILENAME) VALUES('oracle.txt');
COMMIT;

SELECT FILENAME FROM dba_text_user.TABLE1 WHERE CONTAINS(FILENAME, 'oracle',1) > 0;

