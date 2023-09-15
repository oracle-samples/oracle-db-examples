package com.oracle.kafka.teq;

import java.util.UUID;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.util.HashMap;
import java.util.Properties;

import org.apache.log4j.Logger;
import org.json.simple.JSONObject;

public class Producer {

	private KafkaProducer<String, String> kafkaProducer;
	private final Logger log = Logger.getLogger(Producer.class.getName());

	public Producer() throws Exception {
		Runtime.getRuntime().addShutdownHook(new Thread() {
			@Override
			public void run() {
				try {
					shutdown();
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Produces a specified number of messages to the specified Kafka topic.
	 *
	 *
	 * @param topicName     The name of the topic the message will be sent.
	 * @param numOfMessages The number of random messages to send to the Kafka
	 *                      topic.
	 * @throws Exception The Exception that will get thrown when an error occurs
	 */
	public void runProducer(String topicName, int numOfMessages) throws Exception {
		for (int i = 0; i < numOfMessages; i++) {
			String key = UUID.randomUUID().toString();
			// use the Message Helper to get a random string
			String message = Utility.generateRandomMessage(i);
			// send the message
			this.sendMessage(topicName, key, message, null);
			Thread.sleep(100);
		}
		this.shutdown();
	}

	/**
	 * Sends a message to the specified Kafka topic.
	 *
	 * @param topicName The name of the topic to where the message will be sent
	 * @param key       The key value for the message
	 * @param message   The content of the message
	 * @param partition The partition number to put the message in
	 * @throws Exception The Exception that will get thrown when an error occurs
	 */
	protected void sendMessage(String topicName, String key, String message, Integer partition) throws Exception {
		ProducerRecord<String, String> producerRecord = new ProducerRecord<>(topicName, partition,
				System.currentTimeMillis() / 1000, key, message);
		HashMap<String, String> msgLogInfo = new HashMap<>();
		msgLogInfo.put("topic", topicName);
		msgLogInfo.put("key", key);
		msgLogInfo.put("message", message);
		log.debug(new JSONObject(msgLogInfo).toJSONString());
		initiateKafkaProducer().send(producerRecord);
	}

	/**
	 * Initiates the Kafka producer.
	 * 
	 * @return The Kafka producer that has been initiated.
	 * @throws Exception The Exception that will get thrown when an error occurs
	 */
	private KafkaProducer<String, String> initiateKafkaProducer() throws Exception {
		if (this.kafkaProducer == null) {
			Properties props = Utility.getProperties();
			this.kafkaProducer = new KafkaProducer<>(props);
		}
		return this.kafkaProducer;
	}

	/**
	 * Closes the Kafka producer that was initiated.
	 * 
	 * @throws Exception The Exception that will get thrown when an error occurs
	 */
	public void shutdown() throws Exception {
		log.info("Producer is shutting down");
		initiateKafkaProducer().close();
	}
}
