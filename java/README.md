# Java based examples
This repository stores examples that demonstrate various concepts to assist Java and JavaScript developers in designing Java database applications (i.e., accessing and processing data from the Oracle Database), leveraging the Java Database Connectivity (JDBC) API, the Univeral Java Connection Pool (UCP), the embedded Java VM (OJVM), Java 8 Nashorn, and JAX-WS. 

The examples let you run client-side database bound Java or JavaScript code either on HotSpot JDK/JRE (or other JVMs) or server-side Java or JavaScript directly in the database leveraging the embedded JVM (a.k.a. OJVM and Java 8 Nashorn engine). In addition, OJVM allows invoking remote SOAP or REST Web Services from within your database session (using SQL, PL/SQL or Java). 

## What's in Oracle database 12c Release 2 for Java Developers? 
* **Java 8**: Java 8 in JDBC/UCP and OJVM; JDBC 4.2
* **JavaScript with Nashorn**: JDBC/UCP, OJVM
* **Performance**: JIT (OJVM), Network Compression over WAN (JDBC), Configurable connection health check frequency (UCP), PL/SQL Callbace interface (JDBC)
* **Scalability**: Shared Pool for Multi-Tenant Database (UCP), Shared Pool for Sharded database (UCP), Sharding Key APIs (JDBC, UCP), DRCP Proxy session sharing, DRCP support for  multiple labels
* **High-Availability**: Java APIs for FAN events (SimpleFan.jar), Planned Maintenance in the driver (JDBC), Application Continuity for XA Datasources, Transaction Guard for XA Datasource
* **Security**: SSL v1.2 / TLS v 1.2 (JDBC)
* **Manageability**: XMLconfiguration (UCP), Enable/disable/suspend/resume feature level logging (JDBC), MAX_THINK_TIME for Transactions in progress (DRCP), new statistics view and AWR reports  
* **Ease of Use** : Web Services Callout (OJVMWCU), Long Identifiers (OJVM), PL/SQL Boolean (JDBC), Debugger for OJVM (Java Debug Wire Protocol)

## [White paper](http://bit.ly/2orH5jf)
## [See our OTN landing page for more information and resources](http://www.oracle.com/technetwork/database/application-development/java/overview/index.html) 
