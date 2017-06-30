
# Nashorn based examples
Java 8 furnishes Nashorn, a JavaScript engine which runs on the JVM including JDK, JRE, and the embeded JVM in the Oracle database a..k.a. OJVM.
This folder stores database related Nashorn based examples (i.e., plain JavaScript + SQL statements) including JavaScript Stored procedures with OJVM, and standalone/client JavaScript functions with JDK/JRE. 

For data access, Nashorn allows interoperability between Java and JavaScript, therefore, the SQL statements are invoked using JDBC which is a portable standard Java API. 
In addition to SQL statements, for JSON collections and documents, you can also use the fluent API (i.e., no SQL, dot notation) using SODA for Java with JavaScript, the beauty of Nashorn (see SODAjs.md for more details).

For JavaScript Stored Procedures, the steps are very simple
1) create/design your JavaScript function in a file 
2) load the JavaScript file into your database schema using the loadjava utility (DBMSJAVASCRIPT role required)
3) invoke it using (i) either DBMS_JAVASCRIPT.run(<JS file>) or (ii) DbmsJavaScript.run Java call, or (iii) using javax.script API 

[See my blog post for more details](http://db360.blogspot.com/search?updated-max=2016-11-09T08:41:00-08:00&max-results=3) 

[Documentation](http://bit.ly/2nstiYQ)

[White paper](http://bit.ly/2orH5jf) What's in Oracle database 12c Release 2 for Java & JavaScript Developers? 

[Community Forum](https://community.oracle.com/community/database/developer-tools/jvm)
