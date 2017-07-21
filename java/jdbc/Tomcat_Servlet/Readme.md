# Tomcat Java Servlet   
The Oracle JDBC drivers allow Java applications to connect and process data in the Oracle Database. **Apache Tomcat** is the application server for building and deploying Java EE applications.  This repository has code samples for a Java Servlet that connects to the Oracle Database using the Oracle JDBC driver.  We have furnished `build.xml` to compile the servlet and the `Readme.md` that has instructions to compile and deploy this servlet on Tomcat. If you have subscribed to any Oracle Database Service on Cloud such as DBCS, EECS, BMCS etc., follow these instructions to verify the database connectivity with Tomcat.  
 
# What you need to install? 

* **Apache Tomcat**: Download and install [Apache Tomcat](https://tomcat.apache.org/)
* **Apache Ant**: Make sure you have [Apache ANT](http://ant.apache.org/) to compile the source code 
* **JDBC driver**: Download the latest JDBC driver [ojdbc8.jar from OTN](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html)  
* **Oracle Database**:  You need to have a working Oracle Database with the credentials to verify the successful connection.  Make sure either you have subscribed to Oracle Database Service on Cloud (DBCS, EECS, BMCS, ExaCS) or installed an Oracle Database on premise. 

# Steps to compile the Java Servlet 

* **Update build.xml**: Download the `build.xml` present in this repository.  Update TOMCAT_HOME to point to the location where Tomcat is installed. 
* **Create a Resource in context.xml**: Download the `context.xml` present in `META-INF` folder.  Update the database URL, username, and password to point to your Oracle Database.  Let us name this datasource as `orcljdbc_ds`
* **Update JDBCSample_Servlet**: Download the `JDBCSample_Servlet` from this repository.  Update the method `getDataSource()` to use the correct Oracle datasource name. E.g.,`orcljdbc_ds` 
* **JDBC driver**: Place the downloaded JDBC driver ojdbc8.jar in `WEB-INF/lib` folder. 
* **Create the war file**: Go to the location where the `build.xml` is located.  Execute the command `ant` that will compile and also create the `JDBCSample.war` file in the `dist` folder. 

# Steps to deploy and run the Java Servlet 

* **Deploy the WAR file**: Copy the `JDBCSample.war` file to TOMCAT_HOME/webapps/ and Start the Tomcat Server  
* **Invoke the Servlet**: Invoke the servlet at `https://localhost:8080/JDBCSample/JDBCSample_Servlet`
* **Check the Results**: Check the results on the page and make sure that it prints driver information retrieved from the Oracle database.  


# Other Resources 

* [Connecting Java Applications to Database Cloud Services](https://blogs.oracle.com/dev2dev/connecting-java-applications-to-database-cloud-services)
* [Using Java Containers with Exadata Express Cloud Service (EECS)](http://www.oracle.com/technetwork/database/application-development/jdbc/jdbc-eecontainers-cloud.html#tomcat)
