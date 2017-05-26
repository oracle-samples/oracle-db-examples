REM
REM DDL for creating a table for the JSON Collection (and documents)
REM for use by testSODA.java and testSODA.js
REM
CREATE TABLE MyFirstJSONCollection (
ID varchar2(255) not null,
CREATED_ON timestamp,
LAST_MODIFIED timestamp,
VERSION varchar2)255) not null,
JSON_DOCUMENT BLOB
)
;