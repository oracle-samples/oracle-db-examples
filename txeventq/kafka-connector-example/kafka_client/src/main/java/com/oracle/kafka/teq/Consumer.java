package com.oracle.kafka.teq;

import org.apache.kafka.clients.consumer.ConsumerRecord;

import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.errors.WakeupException;
import org.apache.log4j.Logger;
import org.json.simple.JSONObject;

import java.util.*;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicBoolean;

public class Consumer {

	private final int BLOCK_TIMEOUT_MS = 3000;
	private KafkaConsumer<String, String> kafkaConsumer = null;
	private final AtomicBoolean closed = new AtomicBoolean(false);

	static Logger log = Logger.getLogger(Consumer.class.getName());

	public Consumer() throws Exception {
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
	 * Retrieves a collection of ConsumerRecords from the specified topic.
	 *
	 * @param topicName The topic to consume from
	 * 
	 * @throws Exception The Exception that will get thrown when an error occurs
	 */
	public void runConsumer(String topicName) throws Exception {
		// keep running forever or until shutdown() is called from another thread.
		try {
			initiateKafkaConsumer().subscribe(List.of(topicName));
			while (!closed.get()) {
				ConsumerRecords<String, String> records = initiateKafkaConsumer()
						.poll(Duration.ofMillis(BLOCK_TIMEOUT_MS));
				if (records.count() == 0) {
					log.info("No message to consume.");
				}

				for (ConsumerRecord<String, String> recordConsumed : records) {
					HashMap<String, String> msgLogInfo = new HashMap<>();
					msgLogInfo.put("topic", topicName);
					msgLogInfo.put("key", recordConsumed.key());
					msgLogInfo.put("message", recordConsumed.value());
					log.info(new JSONObject(msgLogInfo).toJSONString());
				}
			}
		} catch (WakeupException e) {
			// Ignore exception if closing
			if (!closed.get())
				throw e;
		}
	}

	/**
	 * Shuts down the Kafka consumer that was initiated.
	 * 
	 * @throws Exception The Exception that will get thrown when an error occurs
	 */
	public void shutdown() throws Exception {
		closed.set(true);
		log.info("Consumer is shutting down.");
		initiateKafkaConsumer().wakeup();
	}

	/**
	 * Initiates the Kafka consumer.
	 * 
	 * @return The Kafka consumer that has been initiated.
	 * @throws Exception The Exception that will get thrown when an error occurs
	 */
	private KafkaConsumer<String, String> initiateKafkaConsumer() throws Exception {
		if (this.kafkaConsumer == null) {
			Properties props = Utility.getProperties();
			this.kafkaConsumer = new KafkaConsumer<>(props);
		}
		return this.kafkaConsumer;
	}
}
