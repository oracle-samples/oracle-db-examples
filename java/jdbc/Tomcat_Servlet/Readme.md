# Tomcat Java Servlet   
The Oracle JDBC drivers allow Java applications to connect and process data in the Oracle Database. Apache Tomcat is the application server for building and deploying Java EE applications.  This repository contains a simple Java servlet along with the build scripts and instructions.  The Java servlet that connects to the Oracle Database and performs some database operations.  The 
 
# What you need to install? 

* **Apache Tomcat**: Download and install the [Apache Tomcat v](http://www.oracle.com/technetwork/middleware/weblogic/downloads/index.html)
* **Apache Ant**: Make sure you have [Apache ANT](http://ant.apache.org/) to compile the source code 
* **JDBC driver**: Download the latest JDBC driver [ojdbc8.jar from OTN](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html)  

# Steps to compile the Java Servlet 

* **Update build.xml**: Download the `build.xml` present in this repository.  Update TOMCAT_HOME to point to the location where Tomcat is installed. 
* **Create a Resource  in context.xml**: Create an Oracle Datasource through the admin console.    Let us name this datasource as `orcljdbc_ds`
* **Update JDBCSample_Servlet**: Download the `JDBCSample_Servlet` from this repository and make sure you are using the correct name of the Oracle datasource created through admin console. i.e., `orcljdbc_ds` in the method `getDataSource()`
* **Create the war file**: Go to the location where the `build.xml` is located.  Execute the command `ant` that will compile and also create the `JDBCSample.war` file in the `dist` folder. 

# Steps to deploy and run the Java Servlet 

* **Deploy the WAR file**: Copy the `JDBCSample.war` file to TOMCAT_HOME/webapps/ and Start the Tomcat Server  
* **Invoke the Servlet**: Invoke the servlet at `https://localhost:8080/JDBCSample/JDBCSample_Servlet`
* **Check the Results**: Check the results on the page and make sure that it prints driver information retrieved from the Oracle database.  
