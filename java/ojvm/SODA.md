# Simple Oracle Document Access (SODA) in OJVM

[SODA for Java](https://github.com/oracle/soda-for-java) is Oracle's fluent Java API for accessing JSON collections and documents without any knowledge of SQL.
See [Getting started with SODA for Java](https://github.com/oracle/soda-for-java/blob/master/doc/Getting-started-example.md) for more details on running testSODA.java with a client JVM (JDK or JRE).
The goal of this write up is to furnish the steps for running testSODA.java in OJVM and manipulate the JSON collection directly in the database session without moving data around.

* **Requirements to run SODA with Java in the database**

(i) Download the [latest orajsoda.jar](https://github.com/oracle/soda-for-java/releases) currently orajsoda-1.0.4.jar 

(ii) Upload orasoda.jar in your database schema
            loadjava -r -v -u hr/hr orajsoda-1.0.4.jar

(iii) Load the [latest javax.json-1.0.4.jar](https://mvnrepository.com/artifact/org.glassfish/javax.json/1.0.4) 
            loadjava -r -v -u hr/hr javax.json-1.0.4.jar

* **Prep testSODA.java for OJVM**

(i) Get (copy/paste) testSODA.java from [Getting started with SODA for Java](https://github.com/oracle/soda-for-java/blob/master/doc/Getting-started-example.md)

(ii) Replace the URL in the connect string with the OJVM server-side connect URL
Replace "jdbc:oracle:thin:@//hostName:port/serviceName";
With "jdbc:default:connection"
The furnished testSODA.java on this page already has the change     

(iii) load the updated testSODA.java in your schema
            loadjava -r -v -user hr/hr testSODA.java

(iv) Create the table for persisting the JSON collection and documents using the furnished JSON-tables.sql

(v) Create a SQL wrapper for invoking the main method
            create or replace procedure testSODA as
            language java name 'testSODA.main(java.lang.String[])';        

(vi) Invoke the wrapper of the main method and display the output
            set serveroutput on
            call dbms_java.set_output(2000);
            call testSODA();

The furnished testSODA.sql performs the steps (v) and (vi).       