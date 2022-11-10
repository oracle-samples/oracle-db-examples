# Design High-Speed Data Ingestion Services Using MQTT, AMQP, and STOMP

This directory contains the code samples for Reactive Streams Ingestion (RSI) integrated with ActiveMQ.
To view the details, visit [Design High-Speed Data Ingestion Services Using MQTT, AMQP, and STOMP](https://blogs.oracle.com/...).

## Prerequisites
- Oracle Database 19c
- JDK 19
- ActiveMQ 5.17.2
- RSI 21.7.0.0
- Maven 3.8.1

## Create a table
The `retailer` table is created with the following statement

```sql
CREATE TABLE retailer (
    rank int,
    msr int,
    retailer varchar(255),
    name varchar(255),
    city varchar(255),
    phone varchar(255),
    terminal_type varchar(255),
    weeks_active int,
    instant_sales_amt varchar(255),
    online_sales_amt varchar(255),
    total_sales_amt varchar(255)
);
```

### Start ActiveMQ
Download ActiveMQ from the [Apache ActiveMQ website](https://activemq.apache.org/components/classic/download/).
Go to the ActiveMQ directory and run the following command to start up ActiveMQ:

```shell
$ cd apache-activemq-5.17.2
$ ./bin/activemq start
INFO: Loading '/Users/tinglwang/Downloads/apache-activemq-5.17.2//bin/env'
INFO: Using java '/Library/Java/JavaVirtualMachines/jdk-11.0.5.jdk/Contents/Home/bin/java'
INFO: Starting - inspect logfiles specified in logging.properties and log4j.properties to get details
INFO: pidfile created : '/Users/tinglwang/Downloads/apache-activemq-5.17.2//data/activemq.pid' (pid '61766')
```

### Configure Listener.java
- To connect to your own database, configure the `URL`, `username` and `password` parameters.

### Running the sample application
Run the following command to start the listener. Note: change the target class to rsi.demo.mqtt.Listener and rsi.demo.stomp.Listener if you want to use the MQTT or STOMP protocol.
The "--enable-preview" argument is required since Virtual Thread is a preview feature in JDK 19.
```shell
$ mvn package
$ java --enable-preview -cp ./target/rsi-demo-0.1.0.jar rsi.demo.amqp.Listener
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
Sep 30, 2022 4:26:00 PM oracle.rsi.logging.ClioSupport _log
INFO: :::Database type is non-sharded.
```

### Sending messages to ActiveMQ
The default path is http://localhost:8161/api/message/event?type=topic and the port number is 8161. You also need to configure the credentials with the default ActiveMQ username and password "admin:admin".
The easiest way is to send the request using cURL command. Post the data that we want to stream to the database as follows.

```shell
$ curl -i -H Accept:application/json -XPOST http://localhost:8161/api/message/event?type=topic -u admin:admin -H Content-Type:application/json -d '{\
"rank": 1,\
"msr": 217,\
"retailer": "100224",\
"name": "Freddys One Stop",\
"city": "Roland",\
"phone": "(918) 503-6288",\
"terminal_type": "Extrema",\
"weeks_active": 37,\
"instant_sales_amt": "$318,600.00 ",\
"online_sales_amt": "$509,803.00 ",\
"total_sales_amt": "$828,403.00 "}'
HTTP/1.1 200 OK
Date: Fri, 30 Sep 2022 20:34:28 GMT
X-FRAME-OPTIONS: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Set-Cookie: JSESSIONID=node01f5up6hqo6g6ljv8l3a2cpzc5.node0; Path=/api; HttpOnly
Expires: Thu, 01 Jan 1970 00:00:00 GMT
messageID: ID:tinglwan-mac-49875-1664560122069-5:5:1:1:1
Content-Length: 12
```

### Close the listener and cleanup
To close the listener, simply send a "SHUTDOWN" message to ActiveMQ and it will do the job. According to ActiveMQ's documentation, adding the "body" parameter is critical otherwise the web servlet will not read the body from the -d parameter, and this will cause an error.

```shell
curl -XPOST -u admin:admin http://localhost:8161/api/message/event?type=topic -d "body=SHUTDOWN"
```

Alternatively, you can run the test with Apache JMeter. Go to [Design High-Speed Data Ingestion Services Using MQTT, AMQP, and STOMP](https://blogs.oracle.com/...) for more details.

Once you've completed the test, stop ActiveMQ by running the following command:

```shell
$ ./bin/activemq stop
```
