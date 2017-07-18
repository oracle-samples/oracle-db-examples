# WebLogicServer Java Servlet   
The Oracle JDBC drivers allow Java applications to connect and process data in the Oracle Database. Oracle WebLogic Server is the application server for building and deploying enterprise Java EE applications.  In this code sample, we  

# What you need to install? 

* **Web Logic Server v12.2.1.2**: Download and install the [WebLogic Server v12.2.1.2](http://www.oracle.com/technetwork/middleware/weblogic/downloads/index.html)
* **Apache Ant**: Make sure you have [Apache ANT](http://ant.apache.org/) to compile the source code 
* **JDBC driver**: You can choose to use the JDBC driver (ojdbc7.jar) that is shipped with WebLogicServer v 12.2.1.2 or you can download and use the latest [ojdbc8.jar from OTN](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html)  

# Steps to compile the Java Servlet 

* **Update build.xml**: Download the `build.xml` present in this repository.  Update the path of the WebLogic Server to point to the location where you have installed WebLogic Server. 
* **Create a Datasource in WebLogicServer**: Assuming that WebLogic Server is setup.  Create an Oracle Datasource through the admin console.  Refer to the blog for more details ["Create and Deploy a Java Servlet using WebLogic Server"](https://blogs.oracle.com/dev2dev/create-and-deploy-a-java-servlet-using-weblogic-server-wls) 
* **WebLogic Server**: Download and install the WebLogic Server v12.2.0.1.0 from this path. 


# Steps to deploy and run the Java Servlet 

* **Apache Ant**: Make sure you have Apache ANT to compile the source code 
* **JDBC driver**: You can choose to use the JDBC driver (ojdbc7.jar) that is shipped with WebLogicServer or you can download the latest 
ojdbc8.jar from OTN and use that. 
* **WebLogic Server**: Download and install the WebLogic Server v12.2.0.1.0 from this path. 

# Other Resources 

* 1 [Create and Deploy a Java Servlet using WebLogic Server](https://blogs.oracle.com/dev2dev/create-and-deploy-a-java-servlet-using-weblogic-server-wls)
* 2 [How to use the latest ojdbc8.jar in WebLogic Server?](http://www.oracle.com/technetwork/database/application-development/jdbc/jdbc-eecontainers-cloud.html)






