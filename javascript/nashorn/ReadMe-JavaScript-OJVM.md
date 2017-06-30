# Running JavaScript in Oracle database

The embedded JVM in Oracle database 12 Release 2 (DB 12.2.0.1) supports Java SE 8 therefore the Nashorn engine.

## Steps for running JavaSript in the Oracle database, using Nashorn on OJVM.

* **load the JavaScript file in the database as a Java Resource**
loadjava -v -u username/password hello.js  <-- replace hello.js by your JS file 
* **Run/Execute the file previously loaded using one of the following 3 methods**

a) Running JavaScript in the Database using DBMS_JAVA.JAVASCRIPT.RUN Procedure
From SQL or PL/SQL
SQL>set serveroutput on
SQL>call dbms_java.set_output(20000);
SQL>call dbms_javascript.run("hello.js");

b) Running JavaScript in the Database using DbmsJavaScript.run Java call

From Java, running in the database (OJVM)
import oracle.aurora.rdbms.DbmsJavaScript; 
…
DbmsJavaScript.run("hello.js");

c) Running JavaScript in the Database using the javax.script API
This approach consists in 4 simple steps (described hereafter) and gives you more flexibility, specifically for functions or procedures accepting a variable number of parameters and/or returning value(s). 
Notes: The direct invocation of Nashorn classes is restricted in Oracle JVM. All scripting mode extensions are disabled in Oracle JVM.

## Steps for invoking JavaScript in the database using the javax.script API
* **Instantiate a script manager**
import javax.script.*;
import java.net.*;
import java.io.*;
  ...
ScriptEngineManager factory = new ScriptEngineManager();

* ** 1.Create an engine**
ScriptEngine engine = factory.getEngineByName("myJSengine");

* ** 2.Pass your resource stream reader as the argument to the eval method of the engine**
URL url = 
  Thread.currentThread().getContextClassLoader().getResource("hello.js");
engine.eval(new InputStreamReader(url.openStream()));
...

* ** 3.Invoke a function of the JavaScript code
 Invocable invocable = (Invocable) engine;
        Object selectResult = 
             invocable.invokeFunction("selectQuery", inputId);      
             
## Turn the javax.script steps into a javax script wrapper class
The furnished InvokeScript.java has all these steps.
The signature may differ depending on your input parameters and return values.
The following SQL script creates the Java class in your schema

create or replace and compile java resource named "InvokeScript" as

@InvokeScript.java

 /
 
 Alternatively, you can simply load the Java class in your schema using
    loadjava -r -v -user hr/hr InvokeScript.java
 
 ## Create a SQL wrapper for the javax.script wrapper class 
 CREATE OR REPLACE FUNCTION invokeScriptEval(inputId varchar2) return varchar2 as language java 
name 'InvokeScript.eval(java.lang.String) return java.lang.String'; 
/