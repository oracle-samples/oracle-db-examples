# OKafka Transactional Examples

The repository contains two transactional OKafka application examples in `Transactional` folder.

1. The Producer `TransactionalProducerOKafka.java`

    - Produces 100 messages into `TX_TOPIC_1` topic.

2. The Consumer `TransactionalConsumerOKafka.java`

    - Consumes 100 messages from `TX_TOPIC_1` topic.

## Task 1: Applications Configurations

The steps to create the topic and to configure the Producer and Consumer follow the same instructions detailed in
[Quickstart Guide](../README.md) with only one difference to the Transactional Producer that requires an additional 
property.

```text
# Property to create a Transactional Producer
oracle.transactional.producer=true
```

## Task 2: Try the Producer
Let’s build and run the Producer. Use your IDE or open a command line (or terminal) and navigate to the folder where you have the project
files `<Quickstart Directory>/`. We can build and run the application by issuing the following command:

```shell
gradle Transactional:Producer:run
```

You should see some output that looks very similar to this:

```text
12:10:52 PM: Executing ':Transactional:Producer:TransactionalProducerOKafka.main()'...

> Task :Transactional:Producer:TransactionalProducerOKafka.main()
{"name":"Programmer100","status":"classy","catagory":"general","region":"north","title":"programmer"}
[main] INFO org.oracle.okafka.clients.producer.ProducerConfig - ProducerConfig values:
	acks = 1
	batch.size = 200
	bootstrap.servers = [localhost:1521]
	buffer.memory = 335544
	client.dns.lookup = use_all_dns_ips
	client.id =
	compression.type = none
	connections.max.idle.ms = 540000
	delivery.timeout.ms = 120000
	enable.idempotence = true
    ...

[main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Transactioal Producer set to true
[main] DEBUG org.oracle.okafka.clients.Metadata - Update Metadata. isBootstap? true
[main] DEBUG org.oracle.okafka.clients.Metadata - Updated cluster metadata version 1 to Cluster(id = null, nodes = [0:localhost:1521:FREEPDB1::], partitions = [], controller = null)
[main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Setting externally supplied database conneciton
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Setting externally supplied db connection null
[main] DEBUG org.oracle.okafka.clients.producer.internals.OracleTransactionManager - [Producer clientId=] Transaction id null
[main] WARN org.oracle.okafka.clients.producer.ProducerConfig - The configuration 'batch.size' was supplied but isn't a known config.
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka version: 3.7.1
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka commitId: 839b886f9b732b15
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka startTimeMs: 1724857854059
[main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Kafka producer started
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Transactional producer trying to connect to BootstrapNode. 0:localhost:1521:FREEPDB1::
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Creating new connection for node 0:localhost:1521:FREEPDB1::
[main] INFO org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Connecting to Oracle Database : jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(PORT=1521)(HOST=localhost))(CONNECT_DATA=(SERVICE_NAME=FREEPDB1)))
[main] INFO org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Database Producer Session_Info:59,29991. Process Id:103759. Instance Name:FREE
[main] INFO org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Connected nodes: [0:localhost:1521:FREEPDB1::]
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] CONNECTED NODES: [0:localhost:1521:FREEPDB1::]
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Leader node is null
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Controller Node null
[main] DEBUG org.oracle.okafka.clients.Metadata - Leader Node for Version null_1:0:localhost:1521:FREEPDB1::
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] getDBConnection: Controller Node and LeaderNode set to 0:localhost:1521:FREEPDB1::
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Returning already created db connection. oracle.jdbc.driver.T4CConnection@2b91004a
[main] DEBUG org.oracle.okafka.clients.producer.internals.OracleTransactionManager - [Producer clientId=] Client Transaction id FREE_OKAFKA_USER_59_29991_28_08_2024_12_10_56_638
[main] DEBUG org.oracle.okafka.clients.producer.internals.OracleTransactionManager - [Producer clientId=] Transaction id FREE_OKAFKA_USER_59_29991_28_08_2024_12_10_56_638
[main] DEBUG org.oracle.okafka.clients.producer.internals.OracleTransactionManager - [Producer clientId=] Client Transaction id FREE_OKAFKA_USER_59_29991_28_08_2024_12_10_56_638
[main] DEBUG org.oracle.okafka.clients.producer.internals.OracleTransactionManager - [Producer clientId=] Client Transaction id FREE_OKAFKA_USER_59_29991_28_08_2024_12_10_56_638
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Returning already created db connection. oracle.jdbc.driver.T4CConnection@2b91004a
....
[main] DEBUG org.oracle.okafka.clients.Metadata - Updated cluster metadata version 2 to Cluster(id = FREE, nodes = [0:localhost:1521:FREEPDB1::], partitions = [Partition(topic = TX_TOPIC_1, partition = 0, leader = INSTANCE_0, replicas = [], isr = [], offlineReplicas = [])], controller = 0:localhost:1521:FREEPDB1::)
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Message for TopicPartition TX_TOPIC_1-0
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Controller 0:localhost:1521:FREEPDB1::
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Leader Node 0:localhost:1521:FREEPDB1::
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Available Topic Publishers Session_Info:59,29991. Process Id:103759. Instance Name:FREE. Acknowledge_mode:0.
....
[main] DEBUG org.oracle.okafka.clients.producer.internals.OracleTransactionManager - [Producer clientId=] Commiting Transaction. TransactionState BEGIN. Local Transaction Id:FREE_OKAFKA_USER_59_29991_28_08_2024_12_10_56_638. Database Connection oracle.jdbc.driver.T4CConnection@2b91004a
[main] DEBUG org.oracle.okafka.clients.producer.internals.OracleTransactionManager - [Producer clientId=] Commiting database transaction at instance: FREE. Session information: 59,29991. Process id:103759.
Produced 100 messages.
[main] INFO org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Closing the Kafka producer with timeoutMillis = 9223372036854775807 ms.
[main] INFO org.apache.kafka.common.metrics.Metrics - Metrics scheduler closed
[main] INFO org.apache.kafka.common.metrics.Metrics - Closing reporter org.apache.kafka.common.metrics.JmxReporter
[main] INFO org.apache.kafka.common.metrics.Metrics - Metrics reporters closed
[main] INFO org.apache.kafka.common.utils.AppInfoParser - App info kafka.producer for  unregistered
[main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Kafka producer has been closed
Producer Closed
```

And, querying the topic `TX_TOPIC_1` at the Database, you should see some output that looks very similar to this:

```roomsql
SQL> select MSGID, ENQUEUE_TIME from TX_TOPIC_1;

MSGID                               ENQUEUE_TIME
___________________________________ __________________________________
00000000000000000000000000660000    28/08/24 15:11:01,442151000 GMT
....
00000000000000000000000000666200    28/08/24 15:11:23,670875000 GMT
00000000000000000000000000666300    28/08/24 15:11:23,888144000 GMT

100 rows selected.
```

## Task 3: Try the Producer with 

Now, let's experience the transactional behavior working when there is any issue during the processing of the messages
before sending. The Producer is prepared to abort the transaction when reaches thirty-three messages and you asked it 
to FAIL just passing "FAIL" as a command-line argument.

```shell
 gradle Transactional:Producer:run --args="FAIL"
```

You should see some output that looks very similar to this:

```text
> Task :Transactional:Producer:run
[main] INFO org.oracle.okafka.clients.producer.ProducerConfig - ProducerConfig values: 
        acks = 1
        batch.size = 200
        ....
[main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Transactioal Producer set to true
[main] DEBUG org.oracle.okafka.clients.Metadata - Update Metadata. isBootstap? true
[main] DEBUG org.oracle.okafka.clients.Metadata - Updated cluster metadata version 1 to Cluster(id = null, nodes = [0:localhost:1521:FREEPDB1::], partitions = [], controller = null)
[main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Setting externally supplied database conneciton 
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Setting externally supplied db connection null
[main] DEBUG org.oracle.okafka.clients.producer.internals.OracleTransactionManager - [Producer clientId=] Transaction id null
[main] WARN org.oracle.okafka.clients.producer.ProducerConfig - The configuration 'batch.size' was supplied but isn't a known config.
[main] WARN org.oracle.okafka.clients.producer.ProducerConfig - The configuration 'allow.auto.create.topics' was supplied but isn't a known config.
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka version: 3.7.1
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka commitId: 839b886f9b732b15
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka startTimeMs: 1724942627369
[main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Kafka producer started
{"name":"Programmer100","status":"classy","catagory":"general","region":"north","title":"programmer"}
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Transactional producer trying to connect to BootstrapNode. 0:localhost:1521:FREEPDB1::
....
[main] INFO org.oracle.okafka.clients.Metadata - Cluster ID: FREE
[main] DEBUG org.oracle.okafka.clients.Metadata - Updated cluster metadata version 2 to Cluster(id = FREE, nodes = [0:localhost:1521:FREEPDB1::], partitions = [Partition(topic = TX_TOPIC_1, partition = 0, leader = INSTANCE_0, replicas = [], isr = [], offlineReplicas = [])], controller = 0:localhost:1521:FREEPDB1::)
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Message for TopicPartition TX_TOPIC_1-0
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Controller 0:localhost:1521:FREEPDB1::
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Leader Node 0:localhost:1521:FREEPDB1::
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Available Topic Publishers Session_Info:58,59501. Process Id:153706. Instance Name:FREE. Acknowledge_mode:0.
....
[main] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer - [Producer clientId=] Available Topic Publishers Session_Info:58,59501. Process Id:153706. Instance Name:FREE. Acknowledge_mode:0.Topics:[TX_TOPIC_1].
Exception while processing record
[main] INFO org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Aborting incomplete transaction
Produced 33 messages. Process aborted and not committed.
[main] INFO org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Closing the Kafka producer with timeoutMillis = 9223372036854775807 ms.
[main] INFO org.apache.kafka.common.metrics.Metrics - Metrics scheduler closed
[main] INFO org.apache.kafka.common.metrics.Metrics - Closing reporter org.apache.kafka.common.metrics.JmxReporter
[main] INFO org.apache.kafka.common.metrics.Metrics - Metrics reporters closed
[main] INFO org.apache.kafka.common.utils.AppInfoParser - App info kafka.producer for  unregistered
[main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer - [Producer clientId=] Kafka producer has been closed
Producer Closed        
```

And, querying the topic `TX_TOPIC_1` at the Database, you should see that the amount of messages didn't change.

## Task 4: Try the Consumer

Let’s now build and run the Consumer. Use your IDE or open a command line (or terminal) and navigate to the folder where you have the project
files `<Quickstart Directory>/`. We can build and run the application by issuing the following command:

```shell
gradle Transactional:Consumer:run
```

You should see some output that looks very similar to this:

```shell
> Task :Transactional:Consumer:TransactionalConsumerOKafka.main()
[main] INFO org.oracle.okafka.clients.consumer.ConsumerConfig - ConsumerConfig values:
	allow.auto.create.topics = true
	auto.commit.interval.ms = 5000
	auto.offset.reset = latest
	bootstrap.servers = [localhost:1521]
	check.crcs = true
	client.dns.lookup = use_all_dns_ips
	client.id = consumer-TX_CONSUMER_GRP_1-1
	client.rack =
	connections.max.idle.ms = 540000
	default.api.timeout.ms = 180000
	enable.auto.commit = false
	exclude.internal.topics = true
	fetch.max.bytes = 52428800
	fetch.max.wait.ms = 500
	fetch.min.bytes = 1
	group.id = TX_CONSUMER_GRP_1
	group.instance.id = null
	heartbeat.interval.ms = 3000
	....
	
[main] DEBUG org.oracle.okafka.clients.consumer.KafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Initializing Kafka Consumer
[main] DEBUG org.oracle.okafka.clients.consumer.KafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Setting up bootstrap cluster
[main] DEBUG org.oracle.okafka.clients.Metadata - Update Metadata. isBootstap? true
[main] DEBUG org.oracle.okafka.clients.Metadata - Updated cluster metadata version 1 to Cluster(id = null, nodes = [0:localhost:1521:FREEPDB1::], partitions = [], controller = null)
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka version: 3.7.1
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka commitId: 839b886f9b732b15
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka startTimeMs: 1724860596395
[main] DEBUG org.oracle.okafka.clients.consumer.KafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Kafka consumer initialized
[main] DEBUG org.oracle.okafka.clients.consumer.KafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Subscribed to topic(s): TX_TOPIC_1
[main] INFO org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Available Nodes 1
[main] DEBUG org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] 0:localhost:1521:FREEPDB1::
[main] INFO org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] All Known nodes are disconnected. Try one time to connect.
[main] INFO org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Initiating connection to node 0:localhost:1521:FREEPDB1::
[main] INFO org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Connecting to Oracle Database : jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(PORT=1521)(HOST=localhost))(CONNECT_DATA=(SERVICE_NAME=FREEPDB1)))
[main] INFO org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Database Consumer Session Info: 222,47901. Process Id 105388 Instance Name FREE
[main] DEBUG org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Connection is established to node 1:localhost:1521:FREEPDB1:FREE:OKAFKA_USER
....
[main] DEBUG org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Returning Connection for node 1:localhost:1521:FREEPDB1:FREE:OKAFKA_USER
[main] DEBUG org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Returning Connection for node 1:localhost:1521:FREEPDB1:FREE:OKAFKA_USER
partition = 0, offset = 100, key = 0, value ={"name":"Programmer100","status":"classy","catagory":"general","region":"north","title":"programmer"}
 Header: RecordHeader(key = CLIENT_ID, value = [70, 73, 82, 83, 84, 95, 67, 76, 73, 69, 78, 84])
Header: RecordHeader(key = REPLY_TO, value = [84, 88, 95, 84, 79, 80, 73, 67, 95, 49, 95, 82, 69, 84, 85, 82, 78])
partition = 0, offset = 101, key = 1, value ={"name":"Programmer100","status":"classy","catagory":"general","region":"north","title":"programmer"}
 Header: RecordHeader(key = CLIENT_ID, value = [70, 73, 82, 83, 84, 95, 67, 76, 73, 69, 78, 84])
Header: RecordHeader(key = REPLY_TO, value = [84, 88, 95, 84, 79, 80, 73, 67, 95, 49, 95, 82, 69, 84, 85, 82, 78])
partition = 0, offset = 102, key = 2, value ={"name":"Programmer100","status":"classy","catagory":"general","region":"north","title":"programmer"}
....
[main] DEBUG org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Committing now for node 1:localhost:1521:FREEPDB1:FREE:OKAFKA_USER=[TX_TOPIC_1-0]
partition = 0, offset = 197, key = 97, value ={"name":"Programmer100","status":"classy","catagory":"general","region":"north","title":"programmer"}
 Header: RecordHeader(key = CLIENT_ID, value = [70, 73, 82, 83, 84, 95, 67, 76, 73, 69, 78, 84])
Header: RecordHeader(key = REPLY_TO, value = [84, 88, 95, 84, 79, 80, 73, 67, 95, 49, 95, 82, 69, 84, 85, 82, 78])
partition = 0, offset = 198, key = 98, value ={"name":"Programmer100","status":"classy","catagory":"general","region":"north","title":"programmer"}
 Header: RecordHeader(key = CLIENT_ID, value = [70, 73, 82, 83, 84, 95, 67, 76, 73, 69, 78, 84])
Header: RecordHeader(key = REPLY_TO, value = [84, 88, 95, 84, 79, 80, 73, 67, 95, 49, 95, 82, 69, 84, 85, 82, 78])
partition = 0, offset = 199, key = 99, value ={"name":"Programmer100","status":"classy","catagory":"general","region":"north","title":"programmer"}
 Header: RecordHeader(key = CLIENT_ID, value = [70, 73, 82, 83, 84, 95, 67, 76, 73, 69, 78, 84])
Header: RecordHeader(key = REPLY_TO, value = [84, 88, 95, 84, 79, 80, 73, 67, 95, 49, 95, 82, 69, 84, 85, 82, 78])
[main] DEBUG org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Commit done
[main] DEBUG org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Response Received OffsetCommit
[main] DEBUG org.oracle.okafka.clients.consumer.internals.ConsumerNetworkClient - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Commited to topic partiton: TX_TOPIC_1-0 with  offset: OffsetAndMetadata{offset=199, leaderEpoch=null, metadata=''}
Received 100 Expected 100. Exiting Now.
Closing OKafka Consumer. Received 100 records.
[main] INFO org.apache.kafka.common.metrics.Metrics - Metrics scheduler closed
[main] INFO org.apache.kafka.common.metrics.Metrics - Closing reporter org.apache.kafka.common.metrics.JmxReporter
[main] INFO org.apache.kafka.common.metrics.Metrics - Metrics reporters closed
[main] INFO org.apache.kafka.common.utils.AppInfoParser - App info kafka.consumer for consumer-TX_CONSUMER_GRP_1-1 unregistered
[main] DEBUG org.oracle.okafka.clients.consumer.KafkaConsumer - [Consumer clientId=consumer-TX_CONSUMER_GRP_1-1, groupId=TX_CONSUMER_GRP_1] Kafka consumer has been closed	
```

## License

Copyright (c) 2019, 2024 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.

[> Quickstart Guide](../README.md)