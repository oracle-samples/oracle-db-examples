# Oracle TxEventQ Connectors

Repository for demonstrating how to use the Oracle TxEventQ Connectors. The repository will contain a Kafka client application 
that will produce or consume from a specified Kafka topic. The Kafka client can be used to produce messages to a specifed Kafka
topic. While the Kafka client is producing to the Kafka topic the Oracle TxEventQ Sink Connector can run and enqueue the messages
from the specified Kafka topic into the specified TxEventQ. After the Oracle TxEventQ Sink Connector has completed enqueuing 
messages from the Kafka topic, the Oracle TxEventQ Source Connector can be used to dequeue the messages from the specified 
TxEventQ. While the Oracle TxEventQ is dequeuing messages into Kafka the specified Kafka topic, the Kafka client consumer
be running to consume from that Kafka topic. 

## Getting started

To use the Oracle TxEventQ Connectors Kafka with a minimum version number of 3.1.0 will need to be downloaded and installed on 
a server. Refer to [Kafka Apache](https://kafka.apache.org/) for information on how to start Kafka. The Oracle TxEventQ 
Connectors requires a minimum Oracle Database version of 21c in order to create a Transactional Event Queue. Download the 
[Oracle TxEventQ Connector](https://mvnrepository.com/artifact/com.oracle.database.messaging/txeventq-connector) from maven.
Read the following [Readme](https://github.com/oracle/okafka/tree/master/connectors) file for how to setup and use the Oracle TxEventQ Connector.

## Setting up database

Clone the project from the repository. Open a bash window and change the directory to the location where the cloned project has been saved.

Copy `initdb.sh.example` to `initdb.sh` and mark it as executable, i.e. `chmod a+x ./initdb.sh`

Modify `initdb.sh` to fill in the hostname, port, name of the CDB, service domain, sys password, user, user password, the name of the seed database, and the name of the
pluggable database to create. The user and user password can be an existing user or a new user to create. To (re)initialize the database, run `./initdb.sh`

The initdb.sh script will create a transactional event queue with the name of **TEQ** with the required privileges that is discussed in the 
[Oracle TxEventQ Connector](https://mvnrepository.com/artifact/com.oracle.database.messaging/txeventq-connector) Readme. Use this queue
name **TEQ** when creating the properties file for the Oracle TxEventQ Sink and Source Connector.

**Note**: `sqlplus` is required and must be in your path.

## Usage

In the kafka_client\src\main\resources there are two properties file a config.properties and log4j.properties file that can can
be modified if required.

Start the Kafka broker by starting the zookeeper and Kafka server as described in the [Oracle TxEventQ Connector](https://mvnrepository.com/artifact/com.oracle.database.messaging/txeventq-connector) Readme.
Create two different Kafka topics with 10 partitions one for the producer to use and one for the consumer to use.

If running Kafka in a Windows environment open command prompt and change to the directory where Kafka has been installed.

Run the following command to create a topic:

```bash
.\bin\windows\kafka-topics.bat --create --topic <name of topic> --bootstrap-server localhost:9092 --partitions 10
```

If running Kafka in a Linux environment open a terminal and change to the directory where Kafka has been installed.

Run the following command in one of the terminals to start zookeeper:

```bash
bin/kafka-topics.sh --create --topic <name of topic> --bootstrap-server localhost:9092 --partitions 10
```
We will use the kafka_client to produce some messages to a specified topic and use the Oracle TxEventQ Sink Connector to enqueue
the messages into the specified transactional event queue.

Start the Oracle TxEventQ Sink Connector. Open a command prompt and change the directory to the kafka_client directory and run the
following command `./runproducer.sh <name of kafka topic> <number of messages to produce>`.

Next, we can use the kafka_client to consume messages from a specified topic that has been enqueued by the TxEventQ Source Connector.

Stop the Oracle TxEventQ Sink Connector and start the Oracle TxEventQ Source Connector. Have the Oracle TxEventQ Source Connector
dequeue messages from the transactional event queue that the Oracle TxEventQ Sink Connector just enqueued into and put into the specified
Kafka topic. Open a command prompt and change the directory to the kafka_client directory and run the following 
command `./runconsumer.sh <name of kafka topic>`. The name of the Kafka topic specified here should be the one the Source Connector is 
dequeing into.


