REM
REM
REM ------------------------------------------------------------------------------
REM Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
REM
REM Portions Copyright 2006-2015, Kuassi Mensah. All rights reserved.
REM https://www.amazon.com/dp/1555583296
REM
REM ------------------------------------------------------------------------------
REM DESCRIPTION
REM
REM The following code sample is provided for illustration purposes only.
REM The default values should work for most applications.
REM Before altering these values for your production system, please
REM test beforehand
REM


create or replace and resolve java source named memtest  as
import oracle.aurora.vm.OracleRuntime;
public class memtest
{

 public static void Tests ()
 {
    System.out.println("getSessionSize(): "
                               + OracleRuntime.getSessionSize());
                               
    System.out.println("Old NewspaceSize(): "
                               + OracleRuntime.getNewspaceSize());
    OracleRuntime.setNewspaceSize(2 * OracleRuntime.getNewspaceSize());                          
    System.out.println("New NewspaceSize(): "
                               + OracleRuntime.getNewspaceSize());
                               
    System.out.println("Old MaxRunspaceSize(): "
                               + OracleRuntime.getMaxRunspaceSize());
    OracleRuntime.setMaxRunspaceSize(2 * OracleRuntime.getMaxRunspaceSize());                          
    System.out.println("New MaxRunspaceSize(): "
                               + OracleRuntime.getMaxRunspaceSize());
                               
    System.out.println("getJavaPoolSize(): "
                               + OracleRuntime.getJavaPoolSize());
    System.out.println("getSessionSoftLimit(): "
                               + OracleRuntime.getSessionSoftLimit());
    System.out.println("Old SessionGCThreshold(): "
                               + OracleRuntime.getSessionGCThreshold());
    OracleRuntime.setSessionGCThreshold(2 * OracleRuntime.getSessionGCThreshold());
    System.out.println("New SessionGCThreshold(): "
                               + OracleRuntime.getSessionGCThreshold());

    System.out.println("Old NewspaceSize: " + OracleRuntime.getNewspaceSize());
    OracleRuntime.setNewspaceSize(2 * OracleRuntime.getNewspaceSize());
    System.out.println("New NewspaceSize: " + OracleRuntime.getNewspaceSize());
    
    System.out.println("Old MaxMemsize: " + OracleRuntime.getMaxMemorySize());
    OracleRuntime.setMaxMemorySize(2 * OracleRuntime.getMaxMemorySize());
    System.out.println("New MaxMemsize: " + OracleRuntime.getMaxMemorySize());
    
    System.out.println("Old JavaStackSize(): "
                                + OracleRuntime.getJavaStackSize());
    OracleRuntime.setJavaStackSize(2 * OracleRuntime.getJavaStackSize());
    System.out.println("New JavaStackSize(): "
                                + OracleRuntime.getJavaStackSize());
    
    System.out.println("Old ThreadStackSize(): "
                                + OracleRuntime.getThreadStackSize());
    OracleRuntime.setThreadStackSize(2 * OracleRuntime.getThreadStackSize());
    System.out.println("New ThreadStackSize(): "
                                + OracleRuntime.getThreadStackSize());
  }
}
/
show errors;

create or replace procedure memtests
  as language java name 
  'memtest.Tests()';
/

show errors;

set serveroutput on
Call dbms_java.set_output(50000);
call memtests();
