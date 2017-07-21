# WebLogicServer Java Servlet   
The Oracle JDBC drivers allow Java applications to connect and process data in the Oracle Database. Oracle WebLogic Server is the application server for building and deploying enterprise Java EE applications.  This repository has code samples for a Java Servlet that connects to the Oracle Database using the Oracle JDBC driver.  We have furnished `build.xml` to compile the servlet and the `Readme.md` that has instructions to compile and deploy this servlet on WebLogic Server. If you have subscribed to any Oracle Database Service on Cloud such as DBCS, EECS, BMCS etc., follow these instructions to verify the connectivity with WebLogic Server.  

# What you need to install? 

* **Web Logic Server v12.2.1.2**: Download and install the [WebLogic Server v12.2.1.2](http://www.oracle.com/technetwork/middleware/weblogic/downloads/index.html)
* **Apache Ant**: Make sure you have [Apache ANT](http://ant.apache.org/) to compile the source code 
* **JDBC driver**: You can choose to use the JDBC driver (ojdbc7.jar) that is shipped with WebLogicServer v 12.2.1.2 or you can download and use the latest [ojdbc8.jar from OTN](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html)  

# Steps to compile the Java Servlet 

* **Update build.xml**: Download the `build.xml` present in this repository.  Update WLS_HOME to point to the location where WebLogic Server is installed. 
* **Create a Datasource in WebLogicServer**: Create an Oracle Datasource through the admin console.  Refer to the blog for more details ["Create and Deploy a Java Servlet using WebLogic Server"](https://blogs.oracle.com/dev2dev/create-and-deploy-a-java-servlet-using-weblogic-server-wls).  Let us name this datasource as `orcljdbc_ds`
* **Update JDBCSample_Servlet**: Download the `JDBCSample_Servlet` from this repository and make sure you are using the correct name of the Oracle datasource created through admin console. i.e., `orcljdbc_ds` in the method `getDataSource()`
* **Create the war file**: Go to the location where the `build.xml` is located.  Execute the command `ant` that will compile and also create the `JDBCSample.war` file in the `dist` folder. 

# Steps to deploy and run the Java Servlet 

* **Deploy the WAR file**: Start the WebLogic Server and open the admin console.  Follow the steps in this [blog](https://blogs.oracle.com/dev2dev/create-and-deploy-a-java-servlet-using-weblogic-server-wls#step8) to deploy `JDBCSample.war` 
* **Invoke the Servlet**: Invoke the servlet at `https://localhost:7001/JDBCSample/JDBCSample_Servlet`
* **Check the Results**: Check the results on the page and make sure that it prints driver information retrieved from the Oracle database. 

# Other Resources 

* [Create and Deploy a Java Servlet using WebLogic Server](https://blogs.oracle.com/dev2dev/create-and-deploy-a-java-servlet-using-weblogic-server-wls)
* [How to use the latest ojdbc8.jar in WebLogic Server?](http://www.oracle.com/technetwork/database/application-development/jdbc/jdbc-eecontainers-cloud.html#wls)
* [Using Java Containers with Exadata Express Cloud Service (EECS)](http://www.oracle.com/technetwork/database/application-development/jdbc/jdbc-eecontainers-cloud.html#wls)







