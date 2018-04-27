
# Basic Samples in JDBC 

"Basic Samples" is the first set of code samples aimed to show case some 
some of the basic operations and using some datatypes (LOB, SQLXML, DATE etc.,)
The samples also contain Universal Connection Pool (UCP) functionalities to show
how to harvest connections, label connections, how to use different timeouts, and
how to configure MBean to monitor UCP statistics etc., Read below for the 
description of the code samples. 

# Creating DB User and Sample Data 
Before you run the code samples, we want you to create a new DB user and the necessary tables. 

Download [SQLDeveloper](http://www.oracle.com/technetwork/developer-tools/sql-developer/downloads/sqldev-downloads-42-3802334.html) or you can use SQLPLUS. Connect to your database and login as SYSADMIN. 
Execute the script [JDBCSampleData.sql](https://github.com/oracle/oracle-db-examples/blob/basicsamples/java/jdbc/BasicSamples/JDBCSampleData.sql) that will create the new database user and the 
tables necessary for the code samples. 

# Running Code Samples 
There are three ways to run the sample.

(a) Run each sample by passing the database URL and database user as the command-line 
options. The password is read from console or standard input.  

```java UCPMultiUsers -l <url> -u <user>```
  
(b) Optionally, each sample has DEFAULT_URL, DEFAULT_USER, and DEFAULT_PASSWORD 
in the file. You can choose to update these values with your database credentials
and run the program. 

(c) If you don't update the defaults, then the program proceeds with the defaults
but, will hit error when connecting as these are dummy values.

----
## DateTimeStampSample.java:
This sample shows illustrates the usage of below Oracle column data types 
DATE, TIMESTAMP, TIMESTAMP WITH TIME ZONE and TIMESTAMP WITH LOCAL TIME ZONE. 
It uses the table 'EMP_DATE_JDBC_SAMPLE' which has dates as columns for 
all the insert, delete, and update operations. 
