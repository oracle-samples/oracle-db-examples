package com.example.demo;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import oracle.AQ.AQAgent;
import oracle.AQ.AQDequeueOption;
import oracle.AQ.AQDriverManager;
import oracle.AQ.AQEnqueueOption;
import oracle.AQ.AQException;
import oracle.AQ.AQMessage;
import oracle.AQ.AQMessageProperty;
import oracle.AQ.AQOracleSession;
import oracle.AQ.AQQueue;
import oracle.AQ.AQQueueProperty;
import oracle.AQ.AQQueueTable;
import oracle.AQ.AQQueueTableProperty;
import oracle.AQ.AQRawPayload;
import oracle.AQ.AQSession;

public class ClassicQueue {

	static Logger logger = LoggerFactory.getLogger(QueueExamples.class);

	public static void main(String[] args){
		AQSession aq_sess = null;
		try {
			aq_sess = createSession();

			createQueue(aq_sess);
			logger.info("---------------createQueue successfully-------------------");

			useCreatedQueue(aq_sess);
			logger.info("---------------useCreatedQueue successfully---------------");

			enqueueAndDequeue(aq_sess);
			logger.info("---------------enqueueAndDequeue successfully-------------");

			multiuserQueue(aq_sess);
			logger.info("---------------multiuserQueue successfully----------------");

			enqueueRAWMessages(aq_sess);
			logger.info("---------------enqueueRAWMessages successfully------------");

			dequeueRawMessages(aq_sess);
			logger.info("---------------dequeueRAWMessages successfully------------");

			dequeueMessagesBrowseMode(aq_sess);
			logger.info("---------------dequeueMessagesBrowseMode successfully------");

			enqueueMessagesWithPriority(aq_sess);
			logger.info("---------------enqueueMessagesWithPriority successfully----");

		} catch (Exception ex) {
			logger.info("Exception-1: " + ex);
			ex.printStackTrace();
		}
	}

	public static AQSession createSession() {
		Connection db_conn;
		AQSession aq_sess = null;
		try {
			Class.forName("oracle.jdbc.driver.OracleDriver");
			db_conn = DriverManager.getConnection(
					"jdbc:oracle:thin:@teqtest_high?TNS_ADMIN=/Users/mayanktayal/Code/Database/Wallet_TEQTest","WINGARDIUM", "password");

			logger.info("JDBC Connection opened ");
			db_conn.setAutoCommit(false);
			Class.forName("oracle.AQ.AQOracleDriver");

			/* Creating an AQ Session: */
			aq_sess = AQDriverManager.createAQSession(db_conn);
			
			logger.info("Successfully created AQSession ");
		} catch (Exception ex) {
			logger.info("Exception: " + ex);
			ex.printStackTrace();
		}
		return aq_sess;
	}

	public static void createQueue(AQSession aq_sess) throws AQException {
		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		AQQueueProperty queue_prop = new AQQueueProperty();

		AQQueueTable q_table = aq_sess.createQueueTable("WINGARDIUM", "classicRawQueueTable", qtable_prop);
		logger.info("Successfully created classicRawQueueTable in WINGARDIUM schema");

		AQQueue queue = aq_sess.createQueue(q_table, "classicRawQueue", queue_prop);
		logger.info("Successfully created classicRawQueue in classicRawQueue");
	}

	public static void useCreatedQueue(AQSession aq_sess) throws AQException {
		
		AQQueueTable q_table = aq_sess.getQueueTable("WINGARDIUM", "classicRawQueueTable");
		logger.info("Successful getQueueTable");

		AQQueue queue = aq_sess.getQueue("WINGARDIUM", "classicRawQueue1");
		logger.info("Successful getQueue"+ queue.getQueueTableName() +"------"+queue.getName());
	}

	public static void enqueueAndDequeue(AQSession aq_sess) throws AQException {

		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		// qtable_prop.setCompatible("8.1");

		AQQueueTable q_table = aq_sess.createQueueTable("WINGARDIUM", "classicRawQueueTable2", qtable_prop);
		logger.info("Successful createQueueTable");

		AQQueueProperty queue_prop = new AQQueueProperty();

		AQQueue queue = aq_sess.createQueue(q_table, "classicRawQueue2", queue_prop);
		logger.info("Successful createQueue");

		queue.start(true, true);
		logger.info("Successful start queue");

		queue.grantQueuePrivilege("ENQUEUE", "WINGARDIUM");
		logger.info("Successful grantQueuePrivilege");
	}

	public static void multiuserQueue(AQSession aq_sess) throws AQException {
		
		AQAgent subs111, subs222;

		/* Creating a AQQueueTable property object (payload type - RAW): */
		AQQueueTableProperty qtable_prop = new AQQueueTableProperty("RAW");
		
		/* Creating a new AQQueueProperty object: */
		AQQueueProperty queue_prop = new AQQueueProperty();
		
		/* Set multiconsumer flag to true: */
		qtable_prop.setMultiConsumer(true);

		/* Creating a queue table in WINGARDIUM schema: */
		AQQueueTable q_table = aq_sess.createQueueTable("WINGARDIUM", "classicRawMultiUserQueueTable1", qtable_prop);
		logger.info("Successful createQueueTable");

		AQQueue queue = aq_sess.createQueue(q_table, "classicRawMultiUserQueue1", queue_prop);
		logger.info("Successful createQueue");

		/* Enable enqueue/dequeue on this queue: */
		queue.start();
		logger.info("Successful start queue");

		/* Add subscribers to this queue: */
		subs111 = new AQAgent("GREEN", null, 0);
		subs222 = new AQAgent("BLUE", null, 0);

		queue.addSubscriber(subs111, null); /* no rule */
		logger.info("Successful addSubscriber 111");

		queue.addSubscriber(subs222, "priority < 2"); /* with rule */
		logger.info("Successful addSubscriber 222");
	}

	public static void enqueueRAWMessages(AQSession aq_sess) throws AQException, SQLException {
		
		String test_data = "new message";
		byte[] b_array;
		
		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		/* Get a handle to a queue-classicRawMultiUserQueue in WINGARDIUM schema: */
		AQQueue queue = aq_sess.getQueue("WINGARDIUM", "classicRawMultiUserQueue");
		logger.info("Successful getQueue");

		/* Creating a message to contain raw payload: */
		AQMessage message = queue.createMessage();

		/* Get handle to the AQRawPayload object and populate it with raw data: */
		b_array = test_data.getBytes();

		AQRawPayload raw_payload = message.getRawPayload();

		raw_payload.setStream(b_array, b_array.length);

		/* Creating a AQEnqueueOption object with default options: */
		AQEnqueueOption enq_option = new AQEnqueueOption();
		
		/* Enqueue the message: */
		queue.enqueue(enq_option, message);

		db_conn.commit();
	}

	public static void dequeueRawMessages(AQSession aq_sess) throws AQException, SQLException {
		
		String test_data = "new message";
		byte[] b_array;
		
		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();
		AQQueue queue = aq_sess.getQueue("WINGARDIUM", "classicRawMultiUserQueue");

		AQMessage message = queue.createMessage();
		b_array = test_data.getBytes();
		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);
		AQEnqueueOption enq_option = new AQEnqueueOption();
		queue.enqueue(enq_option, message);
		db_conn.commit();

		/* Creating a AQDequeueOption object with default options: */
		AQDequeueOption deq_option = new AQDequeueOption();

		/* Dequeue a message: */
		deq_option.setConsumerName("GREEN");
		message = queue.dequeue(deq_option);

		/* Retrieve raw data from the message: */
		raw_payload = message.getRawPayload();

		b_array = raw_payload.getBytes();

		db_conn.commit();
	}

	public static void dequeueMessagesBrowseMode(AQSession aq_sess) throws AQException, SQLException {
	
		String test_data = "new message";
		byte[] b_array;
		
		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		/* Get a handle to a queue  in WINGARDIUM schema: */
		AQQueue queue = aq_sess.getQueue("WINGARDIUM", "classicRawMultiUserQueue");
		logger.info("Successful getQueue");

		/* Creating a message to contain raw payload: */
		AQMessage message = queue.createMessage();

		/* Get handle to the AQRawPayload object and populate it with raw data: */
		b_array = test_data.getBytes();

		AQRawPayload raw_payload = message.getRawPayload();
		raw_payload.setStream(b_array, b_array.length);

		AQEnqueueOption enq_option = new AQEnqueueOption();

		queue.enqueue(enq_option, message);
		logger.info("Successful enqueue");

		db_conn.commit();

		AQDequeueOption deq_option = new AQDequeueOption();

		deq_option.setConsumerName("GREEN");

		/* Set dequeue mode to BROWSE: */
		deq_option.setDequeueMode(AQDequeueOption.DEQUEUE_BROWSE);

		/* Set wait time to 10 seconds: */
		deq_option.setWaitTime(10);

		/* Dequeue a message: */
		message = queue.dequeue(deq_option);

		/* Retrieve raw data from the message: */
		raw_payload = message.getRawPayload();
		b_array = raw_payload.getBytes();

		String ret_value = new String(b_array);
		logger.info("Dequeued message: " + ret_value);

		db_conn.commit();
	}

	public static void enqueueMessagesWithPriority(AQSession aq_sess) throws AQException, SQLException {
		 
		String test_data;
		byte[] b_array;
		Connection db_conn = ((AQOracleSession) aq_sess).getDBConnection();

		/* Get a handle to a queue in WINGARDIUM schema: */
		AQQueue queue = aq_sess.getQueue("WINGARDIUM", "classicRawMultiUserQueue");
		logger.info("Successful getQueue");

		/* Enqueue 5 messages with priorities with different priorities: */
		for (int i = 0; i < 5; i++) {
			/* Creating a message to contain raw payload: */
			AQMessage message = queue.createMessage();

			test_data = "Small_message_" + (i + 1); /* some test data */

			b_array = test_data.getBytes();

			AQRawPayload raw_payload = message.getRawPayload();
			raw_payload.setStream(b_array, b_array.length);
			AQMessageProperty m_property = message.getMessageProperty();

			if (i < 2)
				m_property.setPriority(2);
			else
				m_property.setPriority(3);

			AQEnqueueOption enq_option = new AQEnqueueOption();

			/* Enqueue the message: */
			queue.enqueue(enq_option, message);
			logger.info("Successful enqueue");
		}
		db_conn.commit();
	}

}
