
# Kafka Java Client for Oracle Transactional Event Queues 

## Building the Kafka Java Client for Oracle TxEventQ distribution

This distribution contains Java source code to provide Kafka Java client compatibility to Oracle Transactional Event Queues. Some Kafka Java producer and consumer applications can migrate seamlessly to Oracle Transactional Event Queues for scalable event streaming directly built into the Oracle Database.

You need to have [Gradle 7.3 or above](http://www.gradle.org/installation) and [Java](http://www.oracle.com/technetwork/java/javase/downloads/index.html) installed.

This distribution contains version 23.4.0.0 of the `Kafka Java Client for Oracle Transactional Event Queues` project. It will be referred as OKafka-23.4.0.0 henceforth. This is tested with JDK 11.0.22 but we recommend using the latest version.

The Kafka Java Client works with Oracle Database 23ai Free version as well as Oracle Database 23ai available on Oracle Autonomous Cloud platform. 

To test this distribution in free Oracle Cloud environment create [Oracle Cloud account](https://docs.cloud.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm) then create [Oracle Autonomous Transaction Processing Database instance](https://docs.oracle.com/en/cloud/paas/autonomous-data-warehouse-cloud/tutorial-getting-started-autonomous-db/index.html) in cloud.   

A database user should be created and should be granted the privileges mentioned in Database user configuration section. Then create a Transactional Event Queue to produce and consume messages.


### Database user configuration ###

To run `OKafka application` against Oracle Database, a database user must be created and must be granted below privileges.

```roomsql
create user <user> identified by <password>
GRANT AQ_USER_ROLE to user;
GRANT CONNECT, RESOURCE, unlimited tablespace to user;
GRANT EXECUTE on DBMS_AQ to user;
GRANT EXECUTE on DBMS_AQADM to user;
GRANT EXECUTE on DBMS_AQIN to user;
GRANT EXECUTE on DBMS_TEQK to user;
GRANT SELECT on GV_$SESSION to user;
GRANT SELECT on V_$SESSION to user;
GRANT SELECT on GV_$INSTANCE to user;
GRANT SELECT on GV_$LISTENER_NETWORK to user;
GRANT SELECT on GV_$PDBS to user;
GRANT SELECT on USER_QUEUE_PARTITION_ASSIGNMENT_TABLE to user;
GRANT SELECT on SYS.DBA_RSRC_PLAN_DIRECTIVES to user;
EXEC DBMS_AQADM.GRANT_PRIV_FOR_RM_PLAN('user');
```

Once user is created and above privileges are granted, connect to Oracle Database as this user and create a Transactional Event Queue using below PL/SQL script. One can also use `KafkaAdmin` interface as shown in `CreateTopic.java` in `examples` directory to create a Transactional Event Queue. 

```roomsql
-- Create an OKafka topic named 'TXEQ' with 5 partition and retention time of 7 days. 
begin
    dbms_aqadm.create_database_kafka_topic( topicname=> 'TXEQ', partition_num=>5, retentiontime => 7*24*3600);
end;
```

#### Connection configuration ####

`OKafka` uses JDBC(thin driver) connection to connect to Oracle Database instance using any one of two security protocols.
 
1. PLAINTEXT 
2. SSL


1.PLAINTEXT: In this protocol a JDBC connection is setup by providing username and password in plain text in ojdbc.prperties file. To use PLAINTEXT protocol user must provide following properties through application.

		security.protocol = "PLAINTEXT"
		bootstrap.servers  = "host:port"
		oracle.service.name = "name of the service running on the instance"        
		oracle.net.tns_admin = "location of ojdbc.properties file"  
		
`ojdbc.properties` file must have below properties
  
        user(in lowercase)=DatabaseUserName
        password(in lowercase)=Password

2.SSL: This protocol requires that, while connecting to Oracle Database, the JDBC driver authenticates database user using Oracle Wallet or Java KeyStore(JKS) files. This protocol is typically used to o connect to Oracle database 23ai instance in Oracle Autonomous cloud. To use this protocol `Okafka` application must specify following properties.

	    security.protocol = "SSL"
        oracle.net.tns_admin = "location containing Oracle Wallet, tnsname.ora and ojdbc.properties file"
        tns.alias = "alias of connection string in tnsnames.ora"        

Directory location provided in `oracle.net.tns_admin` property should have 
1. Oracle Wallet
2. tnsnames.ora file
3. ojdbc.properties file (optional) 
This depends on how the Oracle Wallet is configured.

Learn more about [JDBC Thin Connections with a Wallet (mTLS)](https://docs.oracle.com/en/cloud/paas/atp-cloud/atpug/connect-jdbc-thin-wallet.html#GUID-5ED3C08C-1A84-4E5A-B07A-A5114951AA9E) to establish secured JDBC connections.
              
Note: tnsnames.ora file in wallet downloaded from Oracle Autonomous Database contains JDBC connection string which is used for establishing JDBC connection.
            
### Building okafka.jar

Simplest way to build the `okafka.jar` file is by using Gradle build tool.
This distribution contains gradle build files which will work for Gradle 7.3 or higher.

```
./gradle jar
```
This generates `okafka-23.4.0.0.jar` in `okafka_source_dir/clients/build/libs`.

**Project Dependency:**

Mandatory jar files for this project to work.

* `ojdbc11-<version>.jar`
* `aqapi-<version>.jar`
* `oraclepki-<version>.jar`
* `osdt_core-<version>.jar`
* `osdt_cert-<version>.jar`
* `javax.jms-api-<version>.jar`
* `jta-<version>.jar`
* `slf4j-api-<version>.jar`
* `kafka-clients-3.7.1.jar`

All these jars are downloaded from Maven Repository during gradle build.

To build the `okafka.jar` file which includes all the dependent jar files in itself.

```
./gradle fullJar 
```
This generates `okafka-full-23.4.0.0.jar` in `okafka_source_dir/clients/build/libs`.

  
## Build javadoc


This command generates javadoc in `okafka_source_dir/clients/build/docs/javadoc`

```
gradle javadoc
```

## Examples

Repository contains 2 common OKafka application examples in `examples` folder.

`1. ProducerOKafka.java`
Produces 10 messages into TxEQ topic.

`2. ConsumerOKafka.java`
Consumes 10 messages from TxEQ topic. 

## Kafka Java Client APIs supported

For detailed documentation of OKafka please refer to [Kafka API for Oracle Transactional Event Queues](https://docs.oracle.com/en/database/oracle/oracle-database/23/adque/Kafka_cient_interface_TEQ.html) documentation.

For list of APIs supported with Oracle 23.4.0.0 version of OKafka please refer to [OKafka 23ai javadoc](https://docs.oracle.com/en/database/oracle/oracle-database/23/okjdc/). 

## Contributing

This project is not accepting external contributions at this time. For bugs or enhancement requests, please file a GitHub issue unless it’s security related. When filing a bug remember that the better written the bug is, the more likely it is to be fixed. If you think you’ve found a security vulnerability, do not raise a GitHub issue and follow the instructions in our [security policy](./SECURITY.md).

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process

## License

Copyright (c) 2019, 2024 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
