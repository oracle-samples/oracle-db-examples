/*
** OKafka Java Client version 23.4.
**
** Copyright (c) 2019, 2024 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.examples;

import org.oracle.okafka.clients.producer.KafkaProducer;

import org.apache.kafka.common.header.internals.RecordHeader;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Properties;
import java.util.concurrent.Future;

public class ProducerOKafka {
	
	public static void main(String[] args) {
		System.setProperty("org.slf4j.simpleLogger.defaultLogLevel", "INFO");

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

		String topic = appProperties.getProperty("topic.name", "TXEQ");
		appProperties.remove("topic.name"); // Pass props to build OKafkaProducer

		Producer<String, String> producer = new KafkaProducer<>(appProperties);

		String baseMsg = "This is test with 128 characters Payload used to test Oracle Kafka. "+
				"Read https://github.com/oracle/okafka/blob/master/README.md";

		Future<RecordMetadata> lastFuture = null;
		int msgCnt = 10;
		String key = "Just some key for OKafka";
		ArrayList<Future<RecordMetadata>> metadataList = new ArrayList<>();

		try {
			for(int i=0;i<msgCnt;i++) {
                RecordHeader rH1 = new RecordHeader("CLIENT_ID", "FIRST_CLIENT".getBytes());
				RecordHeader rH2 = new RecordHeader("REPLY_TO", "TXEQ_2".getBytes());
				ProducerRecord<String, String> producerRecord =
						new ProducerRecord<>(topic, key+i, i+ baseMsg);
                producerRecord.headers().add(rH1).add(rH2);
				lastFuture = producer.send(producerRecord);
				metadataList.add(lastFuture);
			}
			RecordMetadata  rd = lastFuture.get();
			System.out.println("Last record placed in " + rd.partition() + " Offset " + rd.offset());
		}
		catch(Exception e) {
			System.out.println("Failed to send messages:");
			e.printStackTrace();
		}
		finally {
			System.out.println("Initiating close");
			producer.close();
		}

	}

	private static java.util.Properties getProperties()  throws IOException {
		InputStream inputStream = null;
		Properties appProperties;

		try {
			Properties prop = new Properties();
			String propFileName = "config.properties";
			inputStream = ProducerOKafka.class.getClassLoader().getResourceAsStream(propFileName);
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
