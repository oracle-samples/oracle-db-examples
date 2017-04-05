# Universal Connection Pool (UCP)  
Oracle Universal Connection Pool (UCP) is a Java Connection Pool used by Java applications to establish connection to the Oracle Database. The Oracle JDBC drivers implement and comply with the latest JDBC specifications.  JDBC specification is a Java standard that provides the interface for connecting from Java to relational databases. 
The JDBC standard is defined and implemented through the standard `java.sql` interfaces. 

**The JDBC Thin driver or a Type 4 driver** is a pure Java driver that can be used in Java applications and applets.  It communicates with the server using Oracle Net Services to access the Oracle Database.  We recommend everyone to use JDBC Thin driver in their applications.  Java applications need to have **ojdbc8.jar** (for JDK8) in their classpath to establish a connection to the database. 

JDBC Thin driver is used by Java applications to connect to various Database Service offerings such as Oracle Database Service **(DBCS)**, Oracle Exadata Express Cloud Service **(EECS)**, and Oracle Database Serice on Bare Metal **(BMCS)**.  Refer to [JDBC and Oracle Database Service on Cloud](http://www.oracle.com/technetwork/database/application-development/jdbc/documentation/index.html) for detailed instructions. 

# What's new in 12.2 ? 

* **New Java Standards**: Java SE 8 and JDBC 4.2 are supported by UCP (ucp.jar) 
* **New Performance features**: 
* **New Scalability features**: 
* **New High Availability features**: 
* 

# Downloads

[Oracle Database 12.2.0.1 UCP Download Page](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html)

# Javadoc 

[12.2 Online UCP Javadoc](http://docs.oracle.com/database/122/JJUAR/toc.htm) 

# Documentation 

[12.2 UCP Developer's Guide](https://docs.oracle.com/database/122/JJUCP/toc.htm) 

# White Papers 

* [Performance, Scalability, Availability, Security, and Manageability with JDBC and UCP in 12.2](http://www.oracle.com/technetwork/database/application-development/jdbc/jdbcanducp122-3628966.pdf)

* [Connection Management Strategies for Java Applications using JDBC and UCP](http://www.oracle.com/technetwork/database/application-development/jdbc-ucp-conn-mgmt-strategies-3045654.pdf)

# Other Resources 

* [UCP Landing Page and Other UCP Whitepapers](http://www.oracle.com/technetwork/database/application-development/jdbc/overview/index.html)

* [Oracle JDBC & UCP Forum](https://community.oracle.com/community/java/database_connectivity/java_database_connectivity/)







