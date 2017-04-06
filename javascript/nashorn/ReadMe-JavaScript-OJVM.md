# Running JavaScript in Oracle database

The embedded JVM in Oracle database 12 Release 2 (DB 12.2.0.1) supports Java SE 8 therefore the Nashorn engine.

## Here are the steps for running JavaSript in the Orace database, using Nashorn on OJVM.

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
This approach (4 steps) gives you more flexibility specifically for functions returning a value and
 taking a variable number of parameters. 
Notes: The direct invocation of Nashorn classes is restricted in Oracle JVM. All scripting mode extensions are disabled in Oracle JVM.

## Invoking JavaScript in the database using the javax.script API requires the following steps:
* **Instantiate a script manager**
import javax.script.*;
import java.net.*;
import java.io.*;
  ...
ScriptEngineManager factory = new ScriptEngineManager();

* **Create an engine**
ScriptEngine engine = factory.getEngineByName("myJSengine");

* **Pass your resource stream reader as the argument to the eval method of the engine**
URL url = 
  Thread.currentThread().getContextClassLoader().getResource("hello.js");
engine.eval(new InputStreamReader(url.openStream()));
...

* **Turn steps (i, ii and iii) into a Java wrapper class  in OJVM** 
The signature may differ depending on your input parameters and return values.
The following script generates the Java wrapper class; you may paste this direcly in a SQL session or  put it in a script file and invoke it. 

create or replace and compile java resource named "InvokeScript" as
import javax.script.*;
import java.net.*;
import java.io.*;
public class InvokeScript {    
     public static String eval(String inputId) throws Exception {
     String output = new String();
     try {
        // create a script engine manager
         ScriptEngineManager factory = new ScriptEngineManager();
        // create a JavaScript engine
        ScriptEngine engine = factory.getEngineByName("javascript");
        //read the script as a java resource
        engine.eval(new InputStreamReader
        (InvokeScript.class.getResourceAsStream("select.js")));
       /*
        * Alternative approach
        * engine.eval(Thread.currentThread().getContextClassLoader().getResource("select.js"));         
        */
        Invocable invocable = (Invocable) engine;
        Object selectResult = 
             invocable.invokeFunction("selectQuery", inputId);
        output = selectResult.toString();
      } catch(Exception e) {
          output =e.getMessage();
     }
   return output;
  }
 }
 /