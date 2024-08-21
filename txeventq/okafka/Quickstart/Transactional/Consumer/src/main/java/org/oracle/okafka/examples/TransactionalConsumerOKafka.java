/*
 ** OKafka Java Client version 23.4.
 **
 ** Copyright (c) 2019, 2024 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */

package org.oracle.okafka.examples;

import java.util.Properties;
import java.sql.Connection;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.common.header.Header;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRebalanceListener;
import org.apache.kafka.clients.consumer.ConsumerRecord;

import org.oracle.okafka.clients.consumer.KafkaConsumer;


public class TransactionalConsumerOKafka {

    // Dummy implementation of ConsumerRebalanceListener interface
    // It only maintains the list of assigned partitions in assignedPartitions list
    static class ConsumerRebalance implements ConsumerRebalanceListener {

        public List<TopicPartition> assignedPartitions = new ArrayList();

        @Override
        public synchronized void onPartitionsAssigned(Collection<TopicPartition>  partitions) {
            System.out.println("Newly Assigned Partitions:");
            for (TopicPartition tp :partitions ) {
                System.out.println(tp);
                assignedPartitions.add(tp);
            }
        }

        @Override
        public synchronized void onPartitionsRevoked(Collection<TopicPartition> partitions) {
            System.out.println("Revoked previously assigned partitions. ");
            for (TopicPartition tp :assignedPartitions ) {
                System.out.println(tp);
            }
            assignedPartitions.clear();
        }
    }

    public static void main(String[] args) {
        Properties props = new Properties();

        // Option 1: Connect to Oracle Database with database username and password
        props.put("security.protocol","PLAINTEXT");
        //IP or Host name where Oracle Database 23ai is running and Database Listener's Port
        props.put("bootstrap.servers", "localhost:1521");
        props.put("oracle.service.name", "freepdb1"); //name of the service running on the database instance
        // location for ojdbc.properties file where user and password properties are saved
        props.put("oracle.net.tns_admin",".");

		/*
		//Option 2: Connect to Oracle Autonomous Database using Oracle Wallet
		//This option to be used when connecting to Oracle autonomous database instance on OracleCloud
		props.put("security.protocol","SSL");
		// location for Oracle Wallet, tnsnames.ora file and ojdbc.properties file
		props.put("oracle.net.tns_admin",".");
		props.put("tns.alias","Oracle23ai_high");
		*/

        //Consumer Group Name
        props.put("group.id" , "CG1");
        props.put("enable.auto.commit","false");

        // Maximum number of records fetched in single poll call
        props.put("max.poll.records", 10);

        props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

        Consumer<String , String> consumer = new KafkaConsumer<String, String>(props);
        ConsumerRebalanceListener rebalanceListener = new ConsumerRebalance();

        consumer.subscribe(Arrays.asList("TXEQ"), rebalanceListener);

        int expectedMsgCnt = 100;
        int msgCnt = 0;
        Connection conn = null;
        boolean fail = false;
        try {
            while(true) {
                try {
                    //Consumes records from the assigned partitions of 'TXEQ' topic
                    ConsumerRecords <String, String> records = consumer.poll(Duration.ofMillis(10000));

                    if (records.count() > 0 )
                    {
                        conn = ((KafkaConsumer<String, String>)consumer).getDBConnection();
                        fail = false;
                        for (ConsumerRecord<String, String> record : records)
                        {
                            System.out.printf("partition = %d, offset = %d, key = %s, value =%s\n ", record.partition(), record.offset(), record.key(), record.value());
                            for(Header h: record.headers())
                            {
                                System.out.println("Header: " +h.toString());
                            }
                            try {
                                processRecord(conn, record);
                            } catch(Exception e) {
                                fail = true;
                                break;
                            }
                        }
                        if(fail){
                            conn.rollback();
                        }
                        else {
                            msgCnt += records.count();
                            consumer.commitSync();
                        }

                        if(msgCnt >= (expectedMsgCnt )) {
                            System.out.println("Received " + msgCnt + " Expected " + expectedMsgCnt +". Exiting Now.");
                            break;
                        }
                    }
                    else {
                        System.out.println("No Record Fetched. Retrying in 1 second");
                        Thread.sleep(1000);
                    }
                }catch(Exception e)
                {
                    System.out.println("Exception while consuming messages: " + e.getMessage());
                    throw e;
                }
            }
        }catch(Exception e)
        {
            System.out.println("Exception from OKafka consumer " + e);
            e.printStackTrace();
        }finally {
            System.out.println("Closing OKafka Consumer. Received "+ msgCnt +" records.");
            consumer.close();
        }
    }

    private static void processRecord(Connection conn, ConsumerRecord<String, String> record)
    {
        //Application specific logic to process the message
    }
}
