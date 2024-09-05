/*
 ** OKafka Java Client version 23.4.
 **
 ** Copyright (c) 2019, 2024 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */

package org.oracle.okafka.examples;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
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

    public static void main(String[] args) {
        System.setProperty("org.slf4j.simpleLogger.defaultLogLevel", "DEBUG");

        // Get application properties
        Properties appProperties = null;
        try {
            appProperties = getProperties();
            if (appProperties == null) {
                System.out.println("Application properties not found!");
                System.exit(-1);
            }
        } catch (Exception e) {
            System.out.println("Application properties not found!");
            System.out.println("Exception: " + e);
            System.exit(-1);
        }

        String topicName = appProperties.getProperty("topic.name", "TXEQ");
        appProperties.remove("topic.name"); // Pass props to build OKafkaProducer

        Consumer<String , String> consumer = new KafkaConsumer<String, String>(appProperties);
        ConsumerRebalanceListener rebalanceListener = new ConsumerRebalance();

        consumer.subscribe(Arrays.asList(topicName), rebalanceListener);

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


    private static java.util.Properties getProperties()  throws IOException {
        InputStream inputStream = null;
        Properties appProperties;

        try {
            Properties prop = new Properties();
            String propFileName = "config.properties";
            inputStream = TransactionalConsumerOKafka.class.getClassLoader().getResourceAsStream(propFileName);
            if (inputStream != null) {
                prop.load(inputStream);
            } else {
                throw new FileNotFoundException("property file '" + propFileName + "' not found.");
            }
            appProperties = prop;

        } catch (Exception e) {
            System.out.println("Exception: " + e);
            throw e;
        } finally {
            if (inputStream != null)
                inputStream.close();
        }
        return appProperties;
    }

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
}
