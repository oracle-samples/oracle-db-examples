/*
 ** OKafka Java Client version 23.4.
 **
 ** Copyright (c) 2019, 2024 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */

package org.oracle.okafka.examples;

import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.errors.DisconnectException;
import org.apache.kafka.common.header.internals.RecordHeader;
import org.apache.kafka.common.KafkaException;

import org.oracle.okafka.clients.producer.KafkaProducer;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.util.Optional;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicBoolean;

public class TransactionalProducerOKafka {

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


        boolean failProcessing = false;
        if ((args != null) && (args.length == 1)) {
            failProcessing = args[0].equals("FAIL");
        }

        String topicName = appProperties.getProperty("topic.name", "TXEQ");
        appProperties.remove("topic.name"); // Pass props to build OKafkaProducer


        Producer<String, String> producer = null;
        try {
            producer = new KafkaProducer<String, String>(appProperties);

            int msgCnt = 100;
            int limitMessages = 33;

            String jsonPayload = "{\"name\":\"Programmer"+msgCnt+"\",\"status\":\"classy\",\"catagory\":\"general\"," +
                    "\"region\":\"north\",\"title\":\"programmer\"}";

            System.out.println(jsonPayload);
            producer.initTransactions();

            Connection conn = ((KafkaProducer<String, String> )producer).getDBConnection();

            // Produce 100 records in a transaction and commit.
            try {
                producer.beginTransaction();
                AtomicBoolean fail = new AtomicBoolean(false);
                int messagesProduced = 0;
                while (messagesProduced < msgCnt) {
                    //Optionally set RecordHeaders
                    RecordHeader rH1 = new RecordHeader("CLIENT_ID", "FIRST_CLIENT".getBytes());
                    RecordHeader rH2 = new RecordHeader("REPLY_TO", (topicName.concat("_RETURN")).getBytes());

                    ProducerRecord<String, String> producerRecord =
                            new ProducerRecord<String, String>(topicName, String.valueOf(messagesProduced), jsonPayload);
                    producerRecord.headers().add(rH1).add(rH2);

                    try {
                        processRecord(conn, producerRecord, failProcessing, messagesProduced, limitMessages);
                    } catch(Exception e) {
                        System.out.println(e.getMessage());
                        //Retry processRecord or abort the OKafka transaction and close the producer
                        fail.set(true);
                        break;
                    }

                    producer.send(producerRecord);
                    messagesProduced++;
                }

                String returnMsg = String.format("Produced %d messages.", messagesProduced);

                if(fail.get()) {   // Failed to process the records. Abort Okafka transaction
                    producer.abortTransaction();
                    System.out.println(returnMsg.concat(" Process aborted and not committed."));

                } else {          // Successfully process all the records. Commit OKafka transaction
                    producer.commitTransaction();
                    System.out.println(returnMsg);
                }

            } catch( DisconnectException dcE) {
                producer.close();
            } catch (KafkaException e) {
                producer.abortTransaction();
            }
        }
        catch(Exception e) {
            System.out.println("Exception in Main " + e );
            e.printStackTrace();
        }
        finally {
            try {
                if(producer != null)
                    producer.close();
            } catch(Exception e) {
                System.out.println("Exception while closing producer " + e);
                e.printStackTrace();

            }
            System.out.println("Producer Closed");
        }
    }

    private static void processRecord(Connection conn, ProducerRecord<String, String> record,
                                      boolean failProcessing,
                                      int messagesProduced, int limitMessages) throws Exception
    {
        //Application specific logic

        // Samples logic to fail during execution and abort the transaction
        if ((failProcessing) && (messagesProduced == limitMessages))
            throw new Exception("Exception while processing record");
    }

    private static java.util.Properties getProperties()  throws IOException {
        InputStream inputStream = null;
        Properties appProperties;

        try {
            Properties prop = new Properties();
            String propFileName = "config.properties";
            inputStream = TransactionalProducerOKafka.class.getClassLoader().getResourceAsStream(propFileName);
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

}