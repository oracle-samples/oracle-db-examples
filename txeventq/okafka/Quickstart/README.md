
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
    dbms_aqadm.create_database_kafka_topic( topicname=> 'TOPIC_1', partition_num=>5, retentiontime => 7*24*3600);
END;
/
```

> TIP:
>
> A Topic can also be created using OKAFKA Administration methods. Or, through the Producer interface which creates a new topic if it was not previously created.
>
> - You can also use `KafkaAdmin` interface as shown in `OKafkaAdminTopic.java` in `Simple/Admin` directory to create a Transactional Event Queue.

## Step 4: Investigate and Try Simple Producer and Consumer

The repository contains two common OKafka application examples in `Simple` folder.

1. The Producer `ProducerOKafka.java`

   - Produces 10 messages into `TOPIC_1` topic.

2. The Consumer `ConsumerOKafka.java`

   - Consumes 10 messages from `TOPIC_1` topic.

### Task 1: Applications Configurations

#### Connection Configuration

`OKafka` uses JDBC(thin driver) connection to connect to Oracle Database instance using any one of two security protocols.

1. PLAINTEXT
2. SSL

For this quickstart we will use PLAINTEXT.

1.PLAINTEXT: In this protocol a JDBC connection is setup by providing username and password in plain text in ojdbc.prperties file. 
To use PLAINTEXT protocol user must provide following properties through application. Edit file `config.properties` at `<Quickstart Directory>/Simple/[Producer|Consumer]/src/main/resources`

```text
security.protocol = "PLAINTEXT"
bootstrap.servers  = "host:port"
oracle.service.name = "name of the service running on the instance"
oracle.net.tns_admin = "location of ojdbc.properties file"  
```

`ojdbc.properties` file must have below properties

```text
user(in lowercase)=DatabaseUserName
password(in lowercase)=Password
```

#### APIs configuration

You can get a detailed description of the Producer, Consumer and Administration APIs in the [Kafka APIs for Oracle Transactional Event Queues Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/23/adque/Kafka_cient_interface_TEQ.html#GUID-5549915E-6509-4065-B05E-E96338F4742C).

> Note: Topic name property should be provided in UPPERCASE.
>
>> ```text
>> topic.name=<Oracle Database TxEventQ Topic, use uppercase>
>> ```

### Task 2: Try the Producer

Let’s build and run the Producer. Use your IDE or open a command line (or terminal) and navigate to the folder where you have the project 
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
13:33:31.866 [main] INFO org.apache.kafka.common.utils.AppInfoParser -- Kafka version: 3.7.1
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
13:33:43.712 [kafka-producer-network-thread | ] INFO org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Batch Send complete, evaluating response TOPIC_1-0
.....
.....
13:33:48.192 [kafka-producer-network-thread | ] INFO org.oracle.okafka.clients.producer.internals.SenderThread -- [Producer clientId=] Batch Send complete, evaluating response TOPIC_1-0
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

```

And, querying the topic `TOPIC_1` at the Database, you should see some output that looks very similar to this:

```roomsql

SQL> select MSGID, ENQUEUE_TIME from TOPIC_1;

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

### Task 3: Try the Consumer

Let’s now build and run the Consumer. Use your IDE or open a command line (or terminal) and navigate to the folder where you have the project
files `<Quickstart Directory>/`. We can build and run the application by issuing the following command:

```cmd
gradle Simple:Consumer:run
```

You should see some output that looks very similar to this:

```cmd
gradle :Simple:Consumer:run

> Task :Simple:Consumer:run
[main] INFO org.oracle.okafka.clients.consumer.ConsumerConfig - ConsumerConfig values:
        allow.auto.create.topics = true
        auto.commit.interval.ms = 5000
        auto.offset.reset = latest
        bootstrap.servers = [localhost:1521]
        check.crcs = true
        client.dns.lookup = use_all_dns_ips
        client.id = consumer-consumer_grp_1-1
        client.rack =
        connections.max.idle.ms = 540000
        default.api.timeout.ms = 180000
        enable.auto.commit = true
        exclude.internal.topics = true
        fetch.max.bytes = 52428800
        fetch.max.wait.ms = 500
        fetch.min.bytes = 1
        group.id = consumer_grp_1
        .....
        value.deserializer = class org.apache.kafka.common.serialization.StringDeserializer

[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka version: 3.7.1
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka commitId: 839b886f9b732b15
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka startTimeMs: 1724268189943
[main] INFO org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-consumer_grp_1-1, groupId=consumer_grp_1] Available Nodes 1
[main] INFO org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-consumer_grp_1-1, groupId=consumer_grp_1] All Known nodes are disconnected. Try one time to connect.
[main] INFO org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-consumer_grp_1-1, groupId=consumer_grp_1] Initiating connection to node 0:localhost:1521:FREEPDB1::
[main] INFO org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer - [Consumer clientId=consumer-consumer_grp_1-1, groupId=consumer_grp_1] Connecting to Oracle Database : jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(PORT=1521)(HOST=localhost))(CONNECT_DATA=(SERVICE_NAME=FREEPDB1)))
[main] INFO org.oracle.okafka.clients.consumer.internals.AQKafkaConsumer - [Consumer clientId=consumer-consumer_grp_1-1, groupId=consumer_grp_1] Database Consumer Session Info: 212,32257. Process Id 55849 Instance Name FREE
[main] INFO org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-consumer_grp_1-1, groupId=consumer_grp_1] Reconnect successful to node 1:localhost:1521:FREEPDB1:FREE:OKAFKA_USER
[main] INFO org.oracle.okafka.clients.Metadata - Cluster ID: FREE
[main] INFO org.oracle.okafka.clients.NetworkClient - [Consumer clientId=consumer-consumer_grp_1-1, groupId=consumer_grp_1] Available Nodes 1
No Record Fetched. Retrying in 1 second
partition = 0, offset = 0, key = Just some key for OKafka0, value =0This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 1, key = Just some key for OKafka1, value =1This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 2, key = Just some key for OKafka2, value =2This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 3, key = Just some key for OKafka3, value =3This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 4, key = Just some key for OKafka4, value =4This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 5, key = Just some key for OKafka5, value =5This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 6, key = Just some key for OKafka6, value =6This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 7, key = Just some key for OKafka7, value =7This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 8, key = Just some key for OKafka8, value =8This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  partition = 0, offset = 9, key = Just some key for OKafka9, value =9This is test with 128 characters Payload used to test Oracle Kafka. Read https://github.com/oracle/okafka/blob/master/README.md
  Committing records10
No Record Fetched. Retrying in 1 second
```

## Step 5: Investigate and Try Administration API

With Administration API it is possible create and delete Topics. 

### Task 1: Try the Producer

Let’s build and run the Admin Example Class. Use your IDE or open a command line (or terminal) and navigate to the folder 
where you have the project files `<Quickstart Directory>/`. We can build and run the application by issuing the following command:

```cmd
gradle Simple:Admin:run 
Usage: java OKafkaAdminTopic [CREATE|DELETE] topic1 ... topicN
```

This command requires at least two parameters. The first is specify if you wants to create or delete the topics informed 
in sequence. For example:

```shell
gradle Simple:Admin:run --args="CREATE TOPIC_ADMIN_2 TOPIC_ADMIN_3"
```

As a result you will see the two new topics created.

```sql
SQL> select name, queue_table, dequeue_enabled,enqueue_enabled, sharded, queue_category, recipients
  2    from all_queues
  3   where OWNER='OKAFKA_USER'
  4*    and QUEUE_TYPE<>'EXCEPTION_QUEUE';

NAME             QUEUE_TABLE      DEQUEUE_ENABLED    ENQUEUE_ENABLED    SHARDED    QUEUE_CATEGORY               RECIPIENTS
________________ ________________ __________________ __________________ __________ ____________________________ _____________
......
TOPIC_ADMIN_2    TOPIC_ADMIN_2      YES                YES              TRUE       Sharded Queue                MULTIPLE
TOPIC_ADMIN_3    TOPIC_ADMIN_3      YES                YES              TRUE       Sharded Queue                MULTIPLE
```


## Transaction in OKafka Examples 

Kafka Client for Oracle Transactional Event Queues allow developers use the transaction API effectively.

Transactions allow for atomic writes across multiple TxEventQ topics and partitions, ensuring that either all messages
within the transaction are successfully written, or none are. For instance, if an error occurs during processing, the 
transaction may be aborted, preventing any of the messages from being committed to the topic or accessed by consumers.

You can now build and run the [Transactional Examples](./Transactional/TRANSACTIONAL_EXAMPLES.MD).

## Want to Learn More?

- [Kafka APIs for Oracle Transactional Event Queues](https://docs.oracle.com/en/database/oracle/oracle-database/19/adque/)
- [Introduction to Transactional Event Queues and Advanced Queuing](https://docs.oracle.com/en/database/oracle/oracle-database/23/adque/aq-introduction.html#GUID-95868022-ECDA-4685-9D0A-52ED7663C84B)
- [https://developer.oracle.com/](https://developer.oracle.com/)

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process

## License

Copyright (c) 2019, 2024 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
