/*-----------------------------------------------------------------------------
 * Copyright 2017, 2019, Oracle and/or its affiliates. All rights reserved.
 *---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------
 * drop_samples.sql
 *   Drops database objects used for cx_Oracle samples.
 *
 * Run this like:
 *   sqlplus sys/syspassword@hostname/servicename as sysdba @drop_samples
 *---------------------------------------------------------------------------*/

whenever sqlerror exit failure

-- get parameters
set echo off termout on feedback off verify off
accept main_user char default pythondemo -
        prompt "Name of main schema [pythondemo]: "
accept edition_user char default pythoneditions -
        prompt "Name of edition schema [pythoneditions]: "
accept edition_name char default python_e1 -
        prompt "Name of edition [python_e1]: "
set feedback on

-- perform work
@@drop_samples_exec.sql

exit
