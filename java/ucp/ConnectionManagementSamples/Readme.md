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
cost of resetting these states. The sample uses applyConnectionLabel() to
apply a connection label and retrieves a connection using getConnection(label) 
by specifying the created label. 

## UCPConnectionHarvestingSample.java:
UCP's Connection Harvesting allows UCP to pro-actively reclaim borrowed 
connections based on pool requirements at run-time, while still giving 
applications control over which borrowed connections should not be reclaimed. 
The sample uses registerConnectionHarvestingCallback to register a connection 
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
 
============================================================================
