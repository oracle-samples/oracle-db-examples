# JDBC based examples  
The Oracle JDBC drivers allow Java applications to connect and process data in the Oracle Database. These are fully compliant with the latest JDBC specifications which defines the standard `java.sql` interfaces. 

**Type 4 and type 2 drivers** The Oracle database furnishes a type 4 driver a.k.a. JDBC-Thin and a type 2 driver a.k.a. JDBC-OCI however, JDBC-Thin  is the most used and recommended driver type. Java applications simply need to have **ojdbc8.jar** (for JDK/JRE 8) in their classpath. 

**Cloud Database Services** The JDBC Thin driver allows connecting to the various Oracle Database Cloud Services including: the Oracle Database Service **(DBCS)**, the Oracle Exadata Express Cloud Service **(EECS)**, and the Oracle Database Service on Bare Metal **(BMCS)**.  Please refer to [JDBC and Oracle Database Service on Cloud](http://www.oracle.com/technetwork/database/application-development/jdbc/documentation/index.html) for detailed instructions. 

**Prerequisite - JDBC Tutorial** The examples in this folder assume a basic knowledge of JDBC [See the JDBC Java Tutorial]( https://docs.oracle.com/javase/tutorial/jdbc/index.html)

# What's New in JDBC in 12.2 ?

* **New Java Standards**: Java SE 8 and JDBC 4.2 are supported by JDBC driver (ojdbc8.jar) 
* **New Performance features**: Network compression over WAN (JDBC)
* **New Scalability features**: Support for Oracle Sharding APIs 
* **New High Availability features**: FAN events support in the driver (JDBC), Application Continuity for XA Datasources, Transaction Guard for XA Datasource, and Java APIs for FAN events (JDBC),
* **New Security features**: Support for TLSv1.1 and TLSv1.2
* **Ease of use**: Wider System Change Numbers (SCNs) 

# Downloads

[Oracle Database 12.2.0.1 JDBC driver Download Page](http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html)

# Javadoc 

[12.2 Online JDBC Javadoc](http://docs.oracle.com/database/122/JAJDB/toc.htm) 

# Documentation 

[12.2 JDBC Developer's Guide](https://docs.oracle.com/database/122/JJDBC/toc.htm) 

# White Papers 

* [Performance, Scalability, Availability, Security, and Manageability with JDBC in 12.2](http://www.oracle.com/technetwork/database/application-development/jdbc/jdbcanducp122-3628966.pdf)

* [Connection Management Strategies for Java Applications using JDBC and UCP](http://www.oracle.com/technetwork/database/application-development/jdbc-ucp-conn-mgmt-strategies-3045654.pdf)

* [What's in Oracle database 12c Release 2 for Java & JavaScript Developers?](http://bit.ly/2orH5jf)

# Other Resources 

* [JDBC Landing Page and Other JDBC Whitepapers](http://www.oracle.com/technetwork/database/application-development/jdbc/overview/index.html)

* [Oracle JDBC Forum](https://community.oracle.com/community/java/database_connectivity/java_database_connectivity/)







