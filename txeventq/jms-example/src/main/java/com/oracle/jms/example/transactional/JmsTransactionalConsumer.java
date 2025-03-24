/*
 ** JMS Transactional Consumer example
 **
 ** Copyright (c) 2019, 2025 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */

package com.oracle.jms.example.transactional;

public class JmsTransactionalConsumer {
	
	public static void main(String[] args) {
		try {
			oracle.jdbc.pool.OracleDataSource ods = new oracle.jdbc.pool.OracleDataSource();
			ods.setURL("jdbc:oracle:thin:@//<HOST>:<PORT>/<SERVICE_NAME>");
			ods.setUser("aqjmsuser"); 
			ods.setPassword("<PASSWORD>");  // Password for aqjmsuser
			jakarta.jms.TopicConnectionFactory cf = oracle.jakarta.jms.AQjmsFactory.getTopicConnectionFactory(ods);
			jakarta.jms.TopicConnection jmsConn = cf.createTopicConnection();
			jakarta.jms.Session jmsSession = jmsConn.createTopicSession(true, jakarta.jms.Session.CLIENT_ACKNOWLEDGE);
			jakarta.jms.Topic topic = jmsSession.createTopic("TOPIC_OUT");
			jakarta.jms.MessageConsumer consumer = jmsSession.createDurableSubscriber(topic, "Consumer1");
			jmsConn.start();
			jakarta.jms.Message msg = null;
			try {
				//Consume message from Oracle Transactional Event Queue
				msg = consumer.receive();
				java.sql.Connection dbConn =  ((oracle.jakarta.jms.AQjmsSession) jmsSession).getDBConnection();
				// Perform database operations
				processMessage(msg,dbConn);
				// Commit database operation and the consumption of the message
				jmsSession.commit();
				System.out.println("Successfully consumed one Message from topic TOPIC_OUT");
			} catch(Exception e)  {
				System.out.println("Exception while consuming JMS Message: "+ e);
				e.printStackTrace();
				try {
					if(msg != null) {
						jmsSession.rollback();
					}
				}catch(Exception rollbackE) {
					System.out.println("Exception during rollback of consumed message: " + rollbackE);
					rollbackE.printStackTrace();
				}
			}finally {
				try {
					jmsSession.close();
				}catch(Exception closeE) {
					System.out.println("Exception while clossing JMS Session: " + closeE);
					closeE.printStackTrace();
				}
				try {
					jmsConn.close();
				}catch(Exception closeE) {
					System.out.println("Exception while clossing JMS Connection: " + closeE);
					closeE.printStackTrace();
				}
			}		
		} catch (Exception e) {
			System.out.println("Exception while setting up JMS Consumer: " + e);
			e.printStackTrace();
			}
	}

	private static void processMessage(jakarta.jms.Message msg, java.sql.Connection dbConn) throws Exception
	{
		//Application specific DML Operation 
		//Intentionally left blank

	}
}
