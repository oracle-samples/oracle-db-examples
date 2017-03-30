# Connection Management Samples in JDBC using UCP, Universal Connection Pool

Brief descriptions of connection management related code samples.

|Author | Date |
|-------|------|
|nirmala.sundarappa|06/14/16|


==============================================================================
Creating a connection is an expensive database operation which
involves several background operations such as network communication, reading 
connection strings, authentication, transaction enlistment, foreground process 
creation and memory allocation.  Each of these processes contributes to the 
amount of time and resources taken to create a connection object. Repeated 
connection creation and destruction will significantly impact Java application 
scalability.

"Connection Management" code samples explain various ways of connecting to an
Oracle Database and explain use-cases to be considered while choosing the 
connection management strategy. The section below provides more details on 
specific connection management strategy. 

============================================================================
## InternalT2Driver.sql & InternalT2Driver.java: 
The server-side Type 2 (T2S) driver (aka KPRB driver) is for Java in the 
database. It uses database session directly for accessing local data. 
T2S driver is used for better performance because it cuts network traffic
between the Java code and the RDBMS SQL engine.

## InternalT4Driver.sql & InternalT4Driver.java:
The server side Type 4(T4S) driver (aka thin/T4 driver) is used for code 
running Java in database session needing access to another session either on
the same RDBMS instance/server or on a remote RDBMS instance/server.

## DataSourceSample.java:
This sample shows how to connect to a simple DataSource 
(oracle.jdbc.pool.OracleDataSource) and how to set connection related 
properties such as `defaultRowPrefetch`, `defaultBatchValue` etc., 

## ProxySessionSample.java and ProxySessionSample.sql:
This sample shows connecting to the Oracle Database using Proxy 
authentication or N-tier authentication. Proxy authentication is the
process of using a middle tier for user authentication. Proxy connections
can be created using any one of the following options. 
(a) USER NAME: Done by supplying the user name or the password or both.
(b) DISTINGUISHED NAME: This is a global name in lieu of the password of
the user being proxied for.
(c) CERTIFICATE:More encrypted way of passing the credentials of the user,
 who is to be proxied, to the database.
    
## UCPSample.java: 
Universal Connection Pool (UCP) is a client side connection pool. UCP 
furnishes a rich set of features to support scalability in single database
instance as well as built-in features to support high-availability and 
scalability in RAC and Active Data Guard environments.  UCP along with RAC,
RAC One and ADG is a tested and certified combination for handling database
failovers.  Refer to this sample for using UCP and setting UCP properties
such as `minPoolSize`, `maxPoolSize`, etc.

## UCPWithTimeoutProperties.java:
UCP furnishes a set of TimeOut properties which can be used to tune 
performance. The sample demonstrates using some of UCP's important Timeout
properties, such as `InactivityTimeout`, `AbandonedConnectionTimeout`, 
`TimeToLiveTimeout`, and `connectionWaitTimeout`.  Each one of the UCP timeout
property can be run independently. Refer to the sample for more details. 

## UCPWebSessionAffinitySample.java:
Web-Session Affinity is a scalability feature of UCP in RAC and Active Data 
Guard environment which attempts to allocate connections from the same RAC 
instance during the life of a Web application.  UCP tries to do a best try 
effort, but, there is no guarantee to get a connection to the same instance. 
UCP Web-Session Affinity is used in applications which expect short lived 
connections to any database instance. 

## UCPConnectionLabelingSample.java:
Connection Labelling allows applications to set custom states ("labels") 
then retrieve connections based on these pre-set states thereby avoiding the
cost of resetting these states. The sample uses `applyConnectionLabel()` to
apply a connection label and retrieves a connection using `getConnection(label)` 
by specifying the created label. 

## UCPConnectionHarvestingSample.java:
UCP's Connection Harvesting allows UCP to pro-actively reclaim borrowed 
connections based on pool requirements at run-time, while still giving 
applications control over which borrowed connections should not be reclaimed. 
The sample uses `registerConnectionHarvestingCallback` to register a connection 
harvesting callback. 
 
## UCPWithDRCPSample.java:
Database Resident Connection Pool (DRCP) is the server side connection pool. 
DRCP should be used in a scenario when there are a number of middle tiers but 
the number of active connections is fairly less than the number of open 
connections.
DRCP when used along with and Universal Connection Pool(UCP) as the client 
side connection pool improves the performance.  The sample shows UCP with DRCP
in action. The purpose of the client-side pooling mechanism is to maintain the
connections to Connection Broker. Client-side connection pools must attach and
detach connections to the connection broker through `attachServerConnection()`
and `detachServerConnection()`. DRCP should be used in a scenario when there are
a number of middle tiers but the number of active connections is fairly less
than the number of open connections. 
 
## DRCPSample.java:
DRCP can be used with or without a client side connection pool. 
Either UCP or any other third party connection pool (eg., C3P0) can be used as
client side pool. Note that, when UCP is used, it takes care of attaching and 
releasing server connections. There is no need to explicitly call 
`attachServerConnection()`/`detachServerConnection()` with UCP. 

============================================================================


