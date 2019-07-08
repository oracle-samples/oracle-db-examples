/*-----------------------------------------------------------------------------
 * Copyright 2017, 2019, Oracle and/or its affiliates. All rights reserved.
 *---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------
 * SetupSamples.sql
 *   Creates and populates schemas with the database objects used by the
 * cx_Oracle samples. An edition is also created for the demonstration of
 * PL/SQL editioning.
 *
 * Run this like:
 *   sqlplus sys/syspassword@hostname/servicename as sysdba @SetupSamples
 *---------------------------------------------------------------------------*/

whenever sqlerror exit failure

-- get parameters
set echo off termout on feedback off verify off
accept main_user char default pythondemo -
        prompt "Name of main schema [pythondemo]: "
accept main_password char prompt "Password for &main_user: " HIDE
accept edition_user char default pythoneditions -
        prompt "Name of edition schema [pythoneditions]: "
accept edition_password char prompt "Password for &edition_user: " HIDE
accept edition_name char default python_e1 -
        prompt "Name of edition [python_e1]: "
set feedback on

-- perform work
@@DropSamplesExec.sql
@@SetupSamplesExec.sql

exit

