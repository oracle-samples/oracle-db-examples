package com.oracle.jms.example.transactional;

public class JmsTransactionalProducer {
	public static void main(String[] args) {
		try {
			oracle.jdbc.pool.OracleDataSource ods = new oracle.jdbc.pool.OracleDataSource();
			ods.setURL("jdbc:oracle:thin:@//<HOST>:<PORT>/<SERVICE_NAME>");
			ods.setUser("aqjmsuser");
			ods.setPassword("Welcome_123#");
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
				try {
					jmsSession.rollback();
				}catch(Exception ignoreE) {}
			}finally {
				try {
					jmsSession.close(); 	jmsConn.close();
				}catch(Exception e) { }
			}		
		} catch (Exception e) {
			System.out.println("Exception " + e);
			e.printStackTrace(); } 
	}
	
	private static void processMessage(jakarta.jms.Message msg, java.sql.Connection dbConn) throws Exception
	{
		//Application specific DML Operation 
		
	}
	}
	
	private static void processMessage(jakarta.jms.Message msg, java.sql.Connection dbConn) throws Exception
	{
		//Application specific DML Operation 
		
	}

}
