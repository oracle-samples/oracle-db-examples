TrimLob Readme
==============

The goal of this code sample is to contrast the performance of the same java code 
running as a stand-alone JDBC code running outside the database, and used as Java stored
procedure running directly in your database session, using OJVM.

1/ Create an empty table with a Varchar2, BLOB, and CLOB columns, using the
TrimLob.sql script (from a SQL*Plus session)

2/ Edit and compile the Java class and execute using it as stand-alone JDBC code:
javac TrimLob.java
java classpath %CLASSPATH% TrimLob


3/ Execute TrimLobSP.sql (from a SQL*Plus session), this creates a Java source directly
 in the database, compiles, publishes/exposes to SQL, executes it in the database, and displays the results.