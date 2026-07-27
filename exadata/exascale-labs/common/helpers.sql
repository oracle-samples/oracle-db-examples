SET ECHO OFF

-- Standard SQLcl and SQL*Plus session settings for the labs.

SET PAGESIZE 100
SET LINESIZE 200
SET TRIMSPOOL ON
SET TAB OFF
SET FEEDBACK ON
SET VERIFY OFF
SET HEADING ON
SET TERMOUT ON
SET SQLBLANKLINES ON
SET LONG 100000
SET LONGCHUNKSIZE 100000
SET SERVEROUTPUT ON
SET TIMING ON

COLUMN inst_id              FORMAT 9999
COLUMN instance_name        FORMAT A16
COLUMN con_id               FORMAT 9999
COLUMN pdb_id               FORMAT 9999
COLUMN name                 FORMAT A30
COLUMN pdb_name             FORMAT A30
COLUMN service_name         FORMAT A35
COLUMN network_name         FORMAT A45
COLUMN open_mode            FORMAT A12
COLUMN restricted           FORMAT A10
COLUMN status               FORMAT A100
COLUMN snapshot_mode        FORMAT A16
COLUMN snapshot_interval    FORMAT A24
COLUMN tablespace_name      FORMAT A24
COLUMN file_id              FORMAT 99999
COLUMN file_name            FORMAT A85
COLUMN autoextensible       FORMAT A14
COLUMN files                FORMAT 99999
COLUMN bytes_mb             FORMAT 9999990.00
COLUMN allocated_gb         FORMAT 9999990.00
COLUMN autoextend_max_gb    FORMAT 9999990.00
COLUMN total_instances      FORMAT 9999
COLUMN read_write_instances FORMAT 9999
COLUMN read_only_instances  FORMAT 9999
COLUMN service_instances    FORMAT 9999
