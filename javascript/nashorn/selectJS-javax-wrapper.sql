REM
REM Running JavaScript using Javax API in OJVM
REM
REM -------------------------------------------------------------
REM Copyright (c) 2017, Oracle and/or its affiliates. All rights
REM reserved.
REM
REM Author Kuassi Mensah
REM 
REM Turn steps i, ii and iii in ReadeMe-JavaScript-OJVM.txt into a Java 
REM wrapper class  in OJVM. 
REM
REM This description is based on select.js
REM For your own JavaScript function, the signature may differ depending
REM on your input parameters and return values.
REM
REM The following script generates the Java wrapper class; 
REM you may paste this direcly in a SQL session 
REM or  put it in a script file and invoke it. 
REM
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


REM Create a SQL wrapper for the eval function
REM Create function
REM
CREATE OR REPLACE FUNCTION invokeScriptEval(inputId varchar2) return varchar2 as language java 
name 'InvokeScript.eval(java.lang.String) return java.lang.String'; 
/

REM
REM Allow calling InvokeScriptEval() from SQL or PL/SQL  
REM
CREATE OR REPLACE PROCEDURE sqldemo(id IN varchar2)
IS
 output varchar2(10000);
BEGIN
 SELECT invokeScriptEval(id) INTO output from dual;
 dbms_output.put_line(output);
END;
/
SHOW ERRORS;