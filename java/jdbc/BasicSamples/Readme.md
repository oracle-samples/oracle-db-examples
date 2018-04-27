
# Basic Samples in JDBC 

"Basic Samples" is the first set of code samples aimed to showcase some 
of the basic operations and using some datatypes (LOB, SQLXML, DATE etc.,)
The samples also contain Universal Connection Pool (UCP) functionalities to show
how to harvest connections, label connections, how to use different timeouts, and
how to configure MBean to monitor UCP statistics etc., 

# Creating DB User and Sample Data 
Before you run the code samples, we want you to create a new DB user and the necessary tables. 

Download [SQLDeveloper](http://www.oracle.com/technetwork/developer-tools/sql-developer/downloads/sqldev-downloads-42-3802334.html) or you can use SQLPLUS. Connect to your database and login as SYSADMIN. 
Execute the script [JDBCSampleData.sql](https://github.com/oracle/oracle-db-examples/blob/basicsamples/java/jdbc/BasicSamples/JDBCSampleData.sql) that will create the new database user (jdbcuser) and the 
tables necessary for the code samples. 

# Running Code Samples 

(a) Download the [latest 12.2.0.1 ojdbc8.jar and ucp.jar](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html) and add these jars to the classpath. 

(b) Run each sample by passing the database URL and database user as the command-line 
options. The password is read from console or standard input.  

```java UCPMultiUsers -l <url> -u <user>```
  
(b) Optionally, each sample has DEFAULT_URL, DEFAULT_USER, and DEFAULT_PASSWORD 
in the file. You can choose to update these values with your database credentials
and run the program. If you don't update the defaults, then the program proceeds with the defaults
but, will hit error when connecting as these are dummy values.

```java UCPMultiUsers```

Read below for the description of the code samples. 

## DateTimeStampSample.java:
This sample shows illustrates the usage of below Oracle column data types 
DATE, TIMESTAMP, TIMESTAMP WITH TIME ZONE and TIMESTAMP WITH LOCAL TIME ZONE. 
It uses the table 'EMP_DATE_JDBC_SAMPLE' which has dates as columns for 
all the insert, delete, and update operations. 

## JDBCUrlSample.java 
This sample shows how to use the easy connection URL, connection URL with connection descriptors, 
and using TNS alias to connect to the Oracle database. 

## JSONBasicSample.java 
This sample shows how to use some of the enhancements in JavaScript Object Notation (JSON) support 
for Oracle Database 12c Release 2 (12.2).

## LobBasicSample.java 
This sample shows how to use different types of LOBs (Large Objects). 
It shows using BLOB, CLOB, and NLOB as datatypes. 

## PLSQLSample.java 
This sample demonstrates the usage of PL/SQL Stored Procedures and Functions in JDBC.

## PreparedStatementBindingsSample.java
This sample shows CRUD operations using the ```PreparedStatement``` with named bindings.

## PreparedStatementSample.java
This simple shows CRUD operations using the ```PreparedStatement``` object.

## SQLXMLSample.java 
This sample shows how to create, insert, and query ``SQLXML`` values. 

 ## StatementSample.java
 This sample shows CRUD operations using the Statement object.
 
 ## UCPBasic.java 
 This sample shows simple steps of how JDBC applications use the Oracle Universal Connection Pool (UCP).
 
  ## UCPHarvesting.java 
 This code sample shows how applications use the connection harvesting feature of UCP.
 
 ## UCPLabeling.java 
 This sample shows how applications use the connection labeling feature of UCP.

 ## UCPManager.java 
 This sample shows how applications use UCP manager's administration functions. 
 
 ## UCPManagerMBean.java 
 This sample shows how applications use UCP manager MBean's administration functions. 
 
 ## UCPMaxConnReuse.java
 This sample shows how applications use the MaxConnectionReuseTime and MaxConnectionReuseCount features of UCP. 
 
 ## UCPMultiUsers.java
 This sample shows how JDBC applications use UCPP to pool connections for different users.
 
 ## UCPTimeouts.java
This sample shows key connection timeout features of UCP such as ConnectionWaitTimeout, InactiveConnectionTimeout, TimeToLiveConnectionTimeout, and AbandonedConnectionTimeout.
     


