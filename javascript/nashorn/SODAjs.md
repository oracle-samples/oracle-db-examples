# SODA for JavaScript Stored Procedures

[SODA for Java](https://github.com/oracle/soda-for-java) is Oracle's fluent Java API for accessing JSON collections and documents without any knowledge of SQL.

See [SODA for Java in the Database](https://github.com/oracle/oracle-db-examples/blob/master/java/ojvm/SODA.md) for running SODA with OJVM. 

The goal of this write up is to furnish the steps for performing fluent JavaScript programming (i.e., No SQL and dot notation) in OJVM and manipulate the JSON collection directly in the database session without moving data around.

**Requirements for SODA for JavaScript Stored Procedures**

JavaScript in Oracle database is enabled using Nashorn in the embedded JVM (a.k.a. OJVM). Leveraging the interoperability of Java and JavaScript with Nashorn, we will  reuse the SODA for Java APIs in JavaScript code.

(i) Follow steps (i), (ii) and (iii) in the section titled [Requirements to run SODA with Java in the database](https://github.com/oracle/oracle-db-examples/blob/master/java/ojvm/SODA.md)


**testSODA.js**

(i) We've rewritten testSODA.java in JavaScript (i.e., testSODA.js), using SODA for Java API. 
Grap testSODA.js from [Oracle DB Examples - JavaScript - Nashorn](https://github.com/oracle/oracle-db-examples/blob/master/javascript/nashorn/testSODA.js)

(ii) load testSODA.js in your  schema using

            loadjava -r -v -user hr/hr testSODA.js


(iii) enable printing SQL output then invoke testSODA.js
            set serveroutput on
            call dbms_java.set_output(2000);
            call dbms_javascript.run('testSODA.js');
 

From a database SQLPLUS session, issue the following call

 sqlplus hr/hr @testSODAjs.sql
 
 You should see the following output
 
     * Retrieving the first document by its key *

    { "name" : "Alex", "friends" : "50" }

    * Retrieving documents representing users with at least 300 friends *

    { "name" : "Mia", "friends" : "300" }
    { "name" : "Gloria", "friends" : "399" }

