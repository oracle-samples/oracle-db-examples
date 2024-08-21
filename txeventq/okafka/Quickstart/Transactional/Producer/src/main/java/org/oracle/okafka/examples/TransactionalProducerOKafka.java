/*
 ** OKafka Java Client version 23.4.
 **
 ** Copyright (c) 2019, 2024 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */

package org.oracle.okafka.examples;

import org.oracle.okafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.KafkaException;
import org.apache.kafka.common.errors.DisconnectException;
import org.apache.kafka.common.header.internals.RecordHeader;

import java.sql.Connection;
import java.util.Properties;

public class TransactionalProducerOKafka {
    public static void main(String[] args) {
        Producer<String, String> producer = null;
        try {
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

            props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
            props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

            //Property to create a Transactional Producer
            props.put("oracle.transactional.producer", "true");

            producer = new KafkaProducer<String, String>(props);

            int msgCnt = 100;
            String jsonPayload = "{\"name\":\"Programmer"+msgCnt+"\",\"status\":\"classy\",\"catagory\":\"general\",\"region\":\"north\",\"title\":\"programmer\"}";
            System.out.println(jsonPayload);
            producer.initTransactions();

            Connection conn = ((KafkaProducer<String, String> )producer).getDBConnection();
            String topicName = "TXEQ";
            // Produce 100 records in a transaction and commit.
            try {
                producer.beginTransaction();
                boolean fail = false;
                for( int i=0;i<msgCnt;i++) {
                    //Optionally set RecordHeaders
                    RecordHeader rH1 = new RecordHeader("CLIENT_ID", "FIRST_CLIENT".getBytes());
                    RecordHeader rH2 = new RecordHeader("REPLY_TO", "TXEQ_2".getBytes());

                    ProducerRecord<String, String> producerRecord =
                            new ProducerRecord<String, String>(topicName, i+"", jsonPayload);
                    producerRecord.headers().add(rH1).add(rH2);
                    try {
                        processRecord(conn, producerRecord);
                    } catch(Exception e) {
                        //Retry processRecord or abort the Okafka transaction and close the producer
                        fail = true;
                        break;
                    }
                    producer.send(producerRecord);
                }

                if(fail) // Failed to process the records. Abort Okafka transaction
                    producer.abortTransaction();
                else // Successfully process all the records. Commit OKafka transaction
                    producer.commitTransaction();

                System.out.println("Produced 100 messages.");
            }catch( DisconnectException dcE) {
                producer.close();
            }catch (KafkaException e) {
                producer.abortTransaction();
            }
        }
        catch(Exception e)
        {
            System.out.println("Exception in Main " + e );
            e.printStackTrace();
        }
        finally {
            try {
                if(producer != null)
                    producer.close();
            }catch(Exception e)
            {
                System.out.println("Exception while closing producer " + e);
                e.printStackTrace();

            }
            System.out.println("Producer Closed");
        }
    }

    private static void processRecord(Connection conn, ProducerRecord<String, String> record) throws Exception
    {
        //Application specific logic
    }

}