
# Kafka Client for Oracle Transactional Event Queues Quickstart Guide

> ### What you'll build
>
> In this quickstart guide, you will learn: 
>  - How to create a Topic to store events using Oracle Transactional Event Queues (TxEventQ)
>  - Build producers and consumers applications of Oracle Transactional Event Queues (TxEventQ)
> using Kafka Client (a.k.a. OKafka). 
>
> > ### What you’ll need
> > **An Integrated Developer Environment (IDE)**
> > - Popular choices include IntelliJ IDEA, Visual Studio Code, or Eclipse, and many more.
> > 
> > **A Java™ Development Kit (JDK)**
> > - We recommend Oracle JDK or GraalVM version 17.
> > 
> > **Oracle Database 23ai Free - Developer release** 
> >
> > **sqlplus or sqlcl**
> > 
> > A tool to **work with containers** from your local environment. 
> > - Popular choices include Podman, or Docker, and many more.
> > - On this quickstart we will use Podman 
> > 
> > **Git**
> > - To clone the quickstart repository.
> > 
> > **Gradle**
> > - To build and run the applications.


## Step 1: Install Oracle Database 23ai Free

We will use Oracle Database 23ai Free image that is available at [Oracle Container Registry](https://container-registry.oracle.com)

```shell
# Podman Secrets Support:
echo "<Your Password>" | podman secret create oracle_pwd -

podman run --name=db23aifree   \
           --secret=oracle_pwd \
           --publish 1521:1521 \
           --detach \
           container-registry.oracle.com/database/free:latest
```

## Step 2: Setting database user password

All the steps in this lab can either be completed in sqlplus or sqlcl. The instructions refer to sqlcl but apart from the initial connection the two options 
are identical. 

1. Start by *sql* and connect to the database PDB **FREEPDB1** as SYS

    ```shell
    sql /nolog
   ```
    ```roomsql
    CONNECT sys/"<Your Password>"@localhost:1521/FREEPDB1 as sysdba
   ```

2. Create a new user in FREEPDB1 with the necessary privileges to create the Topic.

    ```roomsql
    CREATE user okafka_user identified by <User Password>;
    GRANT resource, connect, unlimited tablespace to okafka_user;
    GRANT aq_user_role to okafka_user;
    GRANT EXECUTE on DBMS_AQ to okafka_user;
    GRANT EXECUTE ON DBMS_AQIN to okafka_user;
    GRANT EXECUTE on DBMS_AQADM to okafka_user;
    GRANT SELECT on GV_$SESSION to okafka_user;
    GRANT SELECT on V_$SESSION to okafka_user;
    GRANT SELECT on GV_$INSTANCE to okafka_user;
    GRANT SELECT on GV_$LISTENER_NETWORK to okafka_user;
    GRANT SELECT on GV_$PDBS to okafka_user;
    GRANT SELECT on USER_QUEUE_PARTITION_ASSIGNMENT_TABLE to okafka_user;
    GRANT select on SYS.DBA_RSRC_PLAN_DIRECTIVES to okafka_user;
    EXEC DBMS_AQADM.GRANT_PRIV_FOR_RM_PLAN('okafka_user');
    COMMIT;
   ```

## Step 3: Create OKafka Topic

Once user is created and above privileges are granted, connect to Oracle Database as this user and create a Transactional Event Queue using below PL/SQL script. 

```roomsql
-- connect to Oracle Database as the new user
CONNECT okafka_user/"<Your Password>"@localhost:1521/FREEPDB1
```

```roomsql
-- Create an OKafka topic named 'TXEQ' with 5 partition and retention time of 7 days. 
BEGIN
    dbms_aqadm.create_database_kafka_topic( topicname=> 'topic_1', partition_num=>5, retentiontime => 7*24*3600);
END;
/
```

> TIP:
> - One can also use `KafkaAdmin` interface as shown in `OKafkaAdminTopic.java` in `Simple/Admin` directory to create a Transactional Event Queue.

## Step 4: Investigate and Try Simple Producer and Consumer

The repository contains 2 common OKafka application examples in `Simple` folder.

1. The Producer `ProducerOKafka.java`

   - Produces 10 messages into `topic_1` topic.

2. The Consumer `ConsumerOKafka.java`

   - Consumes 10 messages from `topic_1` topic.


### Task 1: Connection Configuration

`OKafka` uses JDBC(thin driver) connection to connect to Oracle Database instance using any one of two security protocols.

      1. PLAINTEXT
      2. SSL

For this quickstart we will use PLAINTEXT.

1.PLAINTEXT: In this protocol a JDBC connection is setup by providing username and password in plain text in ojdbc.prperties file. 
To use PLAINTEXT protocol user must provide following properties through application. Edit file `config.properties` at `<Quickstart Directory>/Simple/[Producer|Consumer]/src/main/resources`

		security.protocol = "PLAINTEXT"
		bootstrap.servers  = "host:port"
		oracle.service.name = "name of the service running on the instance"        
		oracle.net.tns_admin = "location of ojdbc.properties file"  

`ojdbc.properties` file must have below properties

        user(in lowercase)=DatabaseUserName
        password(in lowercase)=Password


### Task 2: Try the Producer

et’s build and run the Producer. Use your IDE or ppen a command line (or terminal) and navigate to the folder where you have the project 
files `<Quickstart Directory>/`. We can build and run the application by issuing the following command:

```cmd
gradle Simple:Producer:run
```

You should see some output that looks very similar to this:

```cmd
❯ gradle :Simple:Producer:run

> Task :Simple:Producer:run
13:33:31.776 [main] INFO org.oracle.okafka.clients.producer.ProducerConfig -- ProducerConfig values:
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
        interceptor.classes = []
        key.serializer = class org.apache.kafka.common.serialization.StringSerializer
        linger.ms = 100
        max.block.ms = 60000
        max.in.flight.requests.per.connection = 5
        max.request.size = 1048576
        metadata.max.age.ms = 300000
        metadata.max.idle.ms = 300000
         .....
        value.serializer = class org.apache.kafka.common.serialization.StringSerializer

13:33:31.791 [main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer -- [Producer clientId=] Transactioal Producer set to false
13:33:31.856 [main] DEBUG org.oracle.okafka.clients.Metadata -- Update Metadata. isBootstap? true
13:33:31.856 [main] DEBUG org.oracle.okafka.clients.Metadata -- Updated cluster metadata version 1 to Cluster(id = null, nodes = [0:localhost:1521:FREEPDB1::], partitions = [], controller = null)
13:33:31.862 [main] INFO org.oracle.okafka.clients.producer.KafkaProducer -- [Producer clientId=] Overriding the default acks to all since idempotence is enabled.
13:33:31.862 [main] INFO org.oracle.okafka.clients.producer.KafkaProducer -- [Producer clientId=] Overriding the default retries config to the recommended value of 2147483647 since the idempotent producer is enabled.
13:33:31.865 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Starting Kafka producer I/O thread.
13:33:31.866 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Sender waiting for 100
13:33:31.866 [main] INFO org.apache.kafka.common.utils.AppInfoParser -- Kafka version: 2.8.1
13:33:31.867 [main] INFO org.apache.kafka.common.utils.AppInfoParser -- Kafka commitId: 839b886f9b732b15
13:33:31.867 [main] INFO org.apache.kafka.common.utils.AppInfoParser -- Kafka startTimeMs: 1724258011865
13:33:31.867 [main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer -- [Producer clientId=] Kafka producer started
13:33:31.871 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Sender waiting for 100
13:33:31.972 [kafka-producer-network-thread | ] INFO org.oracle.okafka.clients.NetworkClient -- [Producer clientId=] Available Nodes 1
13:33:31.972 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.NetworkClient -- [Producer clientId=] 0:localhost:1521:FREEPDB1::
13:33:31.972 [kafka-producer-network-thread | ] INFO org.oracle.okafka.clients.NetworkClient -- [Producer clientId=] All Known nodes are disconnected. Try one time to connect.
13:33:31.972 [kafka-producer-network-thread | ] INFO org.oracle.okafka.clients.NetworkClient -- [Producer clientId=] Initiating connection to node 0:localhost:1521:FREEPDB1::
.....
.....
13:33:42.413 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.NetworkClient -- [Producer clientId=] Sending Request: Produce
13:33:42.413 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer -- [Producer clientId=] Publish request for node 0:localhost:1521:FREEPDB1::
13:33:42.413 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.producer.internals.AQKafkaProducer -- [Producer clientId=] Found a publisher Session_Info:37,53002. Process Id:49814. Instance Name:FREE. Acknowledge_mode:0. for node 0:localhost:1521:FREEPDB1::
13:33:43.125 [kafka-producer-network-thread | ] INFO org.oracle.okafka.clients.producer.internals.AQKafkaProducer -- [Producer clientId=] In BulkSend: #messages = 1
13:33:43.711 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.NetworkClient -- [Producer clientId=] Response Received Produce
13:33:43.712 [kafka-producer-network-thread | ] INFO org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Batch Send complete, evaluating response topic_1-0
.....
.....
13:33:48.192 [kafka-producer-network-thread | ] INFO org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Batch Send complete, evaluating response topic_1-0
13:33:48.192 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Sender waiting for 100
Last record placed in 0 Offset 9
Initiating close
13:33:48.195 [main] INFO org.oracle.okafka.clients.producer.KafkaProducer -- [Producer clientId=] Closing the Kafka producer with timeoutMillis = 9223372036854775807 ms.
13:33:48.293 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Beginning shutdown of Kafka producer I/O thread, sending remaining records.
13:33:48.737 [kafka-producer-network-thread | ] DEBUG org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Shutdown of Kafka producer I/O thread has completed.
13:33:48.737 [main] INFO org.apache.kafka.common.metrics.Metrics -- Metrics scheduler closed
13:33:48.738 [main] INFO org.apache.kafka.common.metrics.Metrics -- Closing reporter org.apache.kafka.common.metrics.JmxReporter
13:33:48.738 [main] INFO org.apache.kafka.common.metrics.Metrics -- Metrics reporters closed
13:33:48.738 [main] INFO org.apache.kafka.common.utils.AppInfoParser -- App info kafka.producer for  unregistered
13:33:48.738 [main] DEBUG org.oracle.okafka.clients.producer.KafkaProducer -- [Producer clientId=] Kafka producer has been closed

BUILD SUCCESSFUL in 17s
3 actionable tasks: 3 executed
```

And, querying the topic `topic_1` at the Database, you should see some output that looks very similar to this:

```roomsql

SQL> select MSGID, ENQUEUE_TIME from topic_1;

MSGID                               ENQUEUE_TIME
___________________________________ __________________________________
00000000000000000000000000660000    21/08/24 16:33:43,266359000 GMT
00000000000000000000000000660100    21/08/24 16:33:43,802624000 GMT
00000000000000000000000000660200    21/08/24 16:33:44,249193000 GMT
00000000000000000000000000660300    21/08/24 16:33:44,694872000 GMT
00000000000000000000000000660400    21/08/24 16:33:45,138653000 GMT
00000000000000000000000000660500    21/08/24 16:33:45,590157000 GMT
00000000000000000000000000660600    21/08/24 16:33:46,101399000 GMT
00000000000000000000000000660700    21/08/24 16:33:46,699642000 GMT
00000000000000000000000000660800    21/08/24 16:33:47,314182000 GMT
00000000000000000000000000660900    21/08/24 16:33:47,841574000 GMT

10 rows selected.
```


## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process

## License

Copyright (c) 2019, 2024 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
