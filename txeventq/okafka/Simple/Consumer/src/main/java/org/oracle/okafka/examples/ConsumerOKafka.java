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
import java.time.Duration;
import java.util.Arrays;

import org.oracle.okafka.clients.consumer.KafkaConsumer;

import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.ConsumerRecord;

public class ConsumerOKafka {
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

		KafkaConsumer<String , String> consumer = new KafkaConsumer<>(appProperties);
		consumer.subscribe(Arrays.asList(topic));


			try {
				while(true) {
					ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(10000));

					for (ConsumerRecord<String, String> record : records)
						System.out.printf("partition = %d, offset = %d, key = %s, value =%s\n  ", record.partition(), record.offset(), record.key(), record.value());

					if (records != null && records.count() > 0) {
						System.out.println("Committing records" + records.count());
						consumer.commitSync();
					} else {
						System.out.println("No Record Fetched. Retrying in 1 second");
						Thread.sleep(1000);
					}
				}
			}catch(Exception e)
			{
				System.out.println("Exception from consumer " + e);
				e.printStackTrace();
			}
			finally {
				consumer.close();
			}

	}

	private static java.util.Properties getProperties()  throws IOException {
		InputStream inputStream = null;
		Properties appProperties = null;

		try {
			Properties prop = new Properties();
			String propFileName = "config.properties";
			inputStream = ConsumerOKafka.class.getClassLoader().getResourceAsStream(propFileName);
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
			inputStream.close();
		}
		return appProperties;
	}
}