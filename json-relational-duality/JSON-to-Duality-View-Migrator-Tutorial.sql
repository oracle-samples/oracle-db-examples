/*
** Copyright (c) 2025 Oracle and/or its affiliates
** The Universal Permissive License (UPL), Version 1.0
**
** Subject to the condition set forth below, permission is hereby granted to any
** person obtaining a copy of this software, associated documentation and/or data
** (collectively the "Software"), free of charge and under any and all copyright
** rights in the Software, and any and all patent rights owned or freely
** licensable by each licensor hereunder covering either (i) the unmodified
** Software as contributed to or provided by such licensor, or (ii) the Larger
** Works (as defined below), to deal in both
**
** (a) the Software, and
** (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
** one is included with the Software (each a "Larger Work" to which the Software
** is contributed by such licensors),
**
** without restriction, including without limitation the rights to copy, create
** derivative works of, display, perform, and distribute the Software and make,
** use, sell, offer for sale, import, export, have made, and have sold the
** Software and the Larger Work(s), and to sublicense the foregoing rights on
** either these or other terms.
**
** This license is subject to the following condition:
** The above copyright notice and either this complete permission notice or at
** a minimum a reference to the UPL must be included in all copies or
** substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
** SOFTWARE.
*/

--    TITLE
--      Working with the JSON-To-Duality Migrator using SQL
--
--    DESCRIPTION
--      This tutorial script walks you through an example of working with
--      the JSON-To-Duality Migrator using Conference scheduling data
--      through SQL.
--
--    PREREQUISITES
--      Ensure that you have Oracle Database 23ai installed and running on a
--      port. Ensure that the compatible parameter is set to 23.0.0.0.
--
--    USAGE
--      Connect to the database as a regular (non-SYS) user and run this
--      script. The user must have the DB_DEVELOPER_ROLE and privileges
--      on the default tablespace.
--      A demo user can be created using this statement:
--       CREATE USER <user> IDENTIFIED BY <password> QUOTA UNLIMITED ON <default tablespace>;
--       GRANT DB_DEVELOPER_ROLE TO <user>;
--
--    NOTES
--      Please go through the duality view documentation
--      (https://docs.oracle.com/en/database/oracle/oracle-database/23/jsnvu/index.html)
--      before this to learn more about duality views and their advantages.

-- We start by populating the initial JSON data. We have three collections,
-- Speaker, Attendee, and Sessions.

CREATE TABLE IF NOT EXISTS SPEAKER (data JSON);
CREATE TABLE IF NOT EXISTS ATTENDEE (data JSON);
CREATE TABLE IF NOT EXISTS SESSIONS (data JSON);

INSERT INTO SPEAKER VALUES
    ('{"_id"            : 101,
       "name"           : "Abdul J.",
       "phoneNumber"    : "222-555-011",
       "yearsAtOracle"  : 25,
       "department"     : "Product Management",
       "sessionsTaught" : [ {"sessionName" : "JSON and SQL",  "type" : "Online", "credits" : 3},
                            {"sessionName" : "PL/SQL or Javascript", "type" : "In-person", "credits" : 5} ]}'
    ),
    ('{"_id"            : 102,
       "name"           : "Betty Z.",
       "yearsAtOracle"  : 30,
       "department"     : "Autonomous Databases",
       "sessionsTaught" : [ {"sessionName" : "Oracle ADB on iPhone", "type" : "Online", "credits" : 3},
                            {"sessionName" : "MongoDB API Internals", "type" : "In-person", "credits" : 4} ]}'
    ),
    ('{"_id"            : 103,
       "name"           : "Colin J.",
       "phoneNumber"    : "222-555-023",
       "yearsAtOracle"  : 27,
       "department"     : "In-Memory and Data",
       "sessionsTaught" : [ {"sessionName" : "JSON Duality Views", "type" : "Online", "credits" : 3} ]}'
    );

INSERT INTO ATTENDEE VALUES
    ('{"_id"      : 1,
       "name"     : "Donald P.",
       "age"      : 20,
       "phoneNumber"   : "222-111-021",
       "grade"    : "A",
       "sessions" : [ {"sessionName" : "JSON and SQL", "credits" : 3},
                      {"sessionName" : "PL/SQL or Javascript", "credits" : 5},
                      {"sessionName" : "MongoDB API Internals", "credits" : 4},
                      {"sessionName" : "JSON Duality Views", "credits" : 3},
                      {"sessionName" : "Oracle ADB on iPhone", "credits" : 3} ]}'
    ),
    ('{"_id"      : 2,
       "name"     : "Elena H.",
       "age"      : 22,
       "phoneNumber"   : "222-112-022",
       "grade"    : "B",
       "sessions" : [ {"sessionName" : "JSON Duality Views", "credits" : 3},
                      {"sessionName" : "MongoDB API Internals", "credits" : 4},
                      {"sessionName" : "JSON and SQL", "credits" : 3} ]}'
    ),
    ('{"_id"      : 3,
       "name"     : "Francis K.",
       "age"      : 23,
       "phoneNumber"   : "222-112-022",
       "grade"    : "C",
       "sessions" : [ {"sessionName" : "MongoDB API Internals", "credits" : 4},
                      {"sessionName" : "JSON and SQL", "credits" : 3} ]}'
    ),
    ('{"_id"      : 4,
       "name"     : "Jatin S.",
       "age"      : 24,
       "phoneNumber"   : "222-113-023",
       "grade"    : "D",
       "sessions" : [ {"sessionName" : "JSON Duality Views", "credits" : 3} ]}'
    );

INSERT INTO SESSIONS VALUES
    ('{"_id"                : "10",
       "sessionName"        : "JSON and SQL",
       "creditHours"        : 3,
       "attendeesEnrolled"  : [ {"_id" : 1, "name" : "Donald P."}, {"_id" : 3, "name" : "Francis K."} ]}'
    ),
    ('{"_id"                : "20",
       "sessionName"        : "PL/SQL or Javascript",
       "creditHours"        : 5,
       "attendeesEnrolled"  : [ {"_id" : 1, "name" : "Donald P."} ]}'
    ),
    ('{"_id"                : "30",
       "sessionName"        : "MongoDB API Internals",
       "creditHours"        : 4,
       "attendeesEnrolled"  : [ {"_id" : 1, "name" : "Donald P."}, {"_id" : 2, "name" : "Elena H."}, {"_id" : 3, "name" : "Francis K."} ]}'
    ),
    ('{"_id"                : "40",
       "sessionName"        : "Oracle ADB on iPhone",
       "creditHours"        : 3,
       "attendeesEnrolled"  : [{"_id" : 1, "name" : "Donald P."}]}'
    ),
    ('{"_id"                : "50",
       "sessionName"        : "JSON Duality Views",
       "creditHours"        : 3,
       "attendeesEnrolled"  : [ {"_id" : 1, "name" : "Donald P."}, {"_id" : 2, "name" : "Elena H."}, {"_id" : 4, "name" : "Jatin S."} ]}'
    );

COMMIT;

-- Next, we run the JSON-to-Duality Migrator by invoking the
-- infer_and_generate_schema procedure.

SET SERVEROUTPUT ON
DECLARE
  schema_sql CLOB;
BEGIN
  -- Infer relational schema
  schema_sql :=
   DBMS_JSON_DUALITY.INFER_AND_GENERATE_SCHEMA(
     JSON('{"tableNames"    : [ "ATTENDEE", "SPEAKER", "SESSIONS" ],
            "useFlexFields" : true,
            "updatability"  : true,
            "minFieldFrequency" : 0,
            "minTypeFrequency"  : 0}'
     )
   );

  -- Print DDL script
  DBMS_OUTPUT.PUT_LINE('DDL Script: ');
  DBMS_OUTPUT.PUT_LINE(schema_sql);

  -- Create relational schema
  EXECUTE IMMEDIATE schema_sql;
END;
/

-- Let’s check the objects created by the tool.
-- Note that the relational schema is completely normalized - one table is
-- created per logical entity, one for speaker (speaker_root), one for attendee
-- (attendee_root), and one for sessions (sessions_root). The many-to-many
-- relationship between attendees and sessions is automatically identified and
-- a mapping table is created to map attendees to sessions.

SELECT object_name, object_type
 FROM user_objects
  WHERE created > sysdate-1/24
   ORDER BY object_type DESC; 

-- Now, let’s validate the schema, which shows no errors (no rows selected) for
-- each duality view, which means that there are no validation failures.

SELECT * FROM DBMS_JSON_DUALITY.VALIDATE_SCHEMA_REPORT(table_name => 'SESSIONS', view_name  => 'SESSIONS_DUALITY');
SELECT * FROM DBMS_JSON_DUALITY.VALIDATE_SCHEMA_REPORT(table_name => 'ATTENDEE', view_name  => 'ATTENDEE_DUALITY');
SELECT * FROM DBMS_JSON_DUALITY.VALIDATE_SCHEMA_REPORT(table_name => 'SPEAKER',  view_name  => 'SPEAKER_DUALITY');

-- Let’s create error logs to log errors for documents that do not get imported
-- successfully.

BEGIN
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => 'SESSIONS', err_log_table_name => 'SESSIONS_ERR_LOG', skip_unsupported => TRUE);
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => 'ATTENDEE', err_log_table_name => 'ATTENDEE_ERR_LOG', skip_unsupported => TRUE);
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => 'SPEAKER',  err_log_table_name  => 'SPEAKER_ERR_LOG', skip_unsupported => TRUE);
END;
/

-- Let’s import the data into the duality views.

BEGIN
  DBMS_JSON_DUALITY.IMPORT_ALL(
                      JSON('{"tableNames" : [ "SESSIONS","ATTENDEE","SPEAKER" ],
                             "viewNames"  : [ "SESSIONS_DUALITY","ATTENDEE_DUALITY","SPEAKER_DUALITY" ],
                             "errorLog"   : [ "SESSIONS_ERR_LOG","ATTENDEE_ERR_LOG","SPEAKER_ERR_LOG" ]}'
                      )
  );
END;
/

-- The error logs are empty, showing that there are no import errors — there
-- are no documents that did not get imported.

SELECT ora_err_number$, ora_err_mesg$, ora_err_tag$ FROM SESSIONS_ERR_LOG;
SELECT ora_err_number$, ora_err_mesg$, ora_err_tag$ FROM ATTENDEE_ERR_LOG;
SELECT ora_err_number$, ora_err_mesg$, ora_err_tag$ FROM SPEAKER_ERR_LOG;

-- Super simple, isn’t it?
-- Download the Oracle Database 23ai Free version from oracle.com/database/free
-- and try it today!
