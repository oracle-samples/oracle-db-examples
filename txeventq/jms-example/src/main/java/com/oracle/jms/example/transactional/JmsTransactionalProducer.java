/*
 ** JMS Transactional Producer example
 **
 ** Copyright (c) 2019, 2025 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */

package com.oracle.jms.example.transactional;

public class JmsTransactionalProducer {
	public static void main(String[] args) {
		try {
			oracle.jdbc.pool.OracleDataSource ods = new oracle.jdbc.pool.OracleDataSource();
			ods.setURL("jdbc:oracle:thin:@//<HOST>:<PORT>/<SERVICE_NAME>");
			ods.setUser("aqjmsuser");
			ods.setPassword("<PASSWORD>");  // Password for aqjmsuser
			jakarta.jms.TopicConnectionFactory cf = oracle.jakarta.jms.AQjmsFactory.getTopicConnectionFactory(ods);
			jakarta.jms.TopicConnection jmsConn = cf.createTopicConnection();
			jakarta.jms.Session jmsSession = jmsConn.createTopicSession(true, jakarta.jms.Session.CLIENT_ACKNOWLEDGE);
			jakarta.jms.Topic topic = jmsSession.createTopic("TOPIC_IN");
			jakarta.jms.MessageProducer jmsProducer = jmsSession.createProducer(topic);
			jakarta.jms.Message msg = jmsSession.createTextMessage("JMS Test Message");
			// Get database connection which will be used to produce a message.
			java.sql.Connection dbConn = ((oracle.jakarta.jms.AQjmsSession)jmsSession).getDBConnection(); 
			try {
				// Perform database operations
				processMessage(msg, dbConn);	
				// Send a message to Oracle Transactional Event Queue.
				jmsProducer.send(msg);
				// Commit Send and database operation
				jmsSession.commit();      
				System.out.println("Successfully Produced one Message into topic TOPIC_IN");
			}catch(Exception e) {
				System.out.println("Exception while producing a message: " + e);
				e.printStackTrace();
				try {
					jmsSession.rollback();
				}catch(Exception rollbackE) {
					System.out.println("Exception during rollback of JMS Session. " + rollbackE);
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
			System.out.println("Exception while setting up JMS Producer" + e);
			e.printStackTrace();
		} 
	}

	private static void processMessage(jakarta.jms.Message msg, java.sql.Connection dbConn) throws Exception
	{
		//Application specific DML Operation 
		//Intentionally left blank

	}
}
