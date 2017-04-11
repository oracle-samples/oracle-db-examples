Workers Readme
==============

The goal of this code sample is to show how to execute the same java code
as a stand-alone JDBC code running outside the database, and used as Java stored
procedure running directly in your database session, using OJVM.

1/ Create a workers table and execute Workers_table.sql from a SQL*Plus session

2/ Edit the database connection URL in the Workers_jdbc Java class and execute using it as stand-alone JDBC code:
javac Workers_jdbc.java
java classpath %CLASSPATH% Workers_jdbc

3/ Execute Workers_OJVM.sql (from a SQL*Plus session), this creates a Java source directly
 in the database, compiles, publishes/exposes to SQL, executes it in the database, and displays the results.