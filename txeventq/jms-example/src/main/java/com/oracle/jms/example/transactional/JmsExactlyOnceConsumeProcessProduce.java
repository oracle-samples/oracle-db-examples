package com.oracle.jms.example.transactional;

public class JmsExactlyOnceConsumeProcessProduce {
	public static void main(String[] args) {
		try {
			oracle.jdbc.pool.OracleDataSource ods = new oracle.jdbc.pool.OracleDataSource();
			ods.setURL("jdbc:oracle:thin:@//<HOST>:<PORT>/<SERVICE_NAME>");
			ods.setUser("aqjmsuser");
			ods.setPassword("Welcome_123#");
			jakarta.jms.TopicConnectionFactory cf = oracle.jakarta.jms.AQjmsFactory.getTopicConnectionFactory(ods);
			jakarta.jms.TopicConnection jmsConn = cf.createTopicConnection();
			jakarta.jms.Session jmsSession = jmsConn.createTopicSession(true, jakarta.jms.Session.CLIENT_ACKNOWLEDGE);
			jakarta.jms.Topic topicIn = jmsSession.createTopic("TOPIC_IN");
			jakarta.jms.MessageConsumer consumer = jmsSession.createDurableSubscriber(topicIn, "Consumer1");			
			jakarta.jms.Topic topicOut = jmsSession.createTopic("TOPIC_OUT");
			jakarta.jms.MessageProducer jmsProducer = jmsSession.createProducer(topicOut);			
			jmsConn.start();
			jakarta.jms.Message msgConsumed = null;
			try {
				msgConsumed = consumer.receive(); 	//Consume message from TOPIC_IN topic
				java.sql.Connection dbConn = ((oracle.jakarta.jms.AQjmsSession) jmsSession).getDBConnection();				
				// Perform database operations for consumed message
				String resultMessage = processMessage(msgConsumed,dbConn);				
				jakarta.jms.Message msgProduce = jmsSession.createTextMessage("PROCESSED:"+ resultMessage);
				jmsProducer.send(msgProduce); 	//Send message to TOPIC_OUT 
				// Commit receive from TOPIC_IN ,Database operation and send to TOPIC_OUT				
				jmsSession.commit();
				System.out.println("Successfully Consumed one message from TOPIC_OUT and produced into TOPIC_IN");
				
			} catch(Exception e){
				try {
					if(msgConsumed != null)
						jmsSession.rollback();
				}catch(Exception rollbackE) {}
			}finally {
				try {
					jmsSession.close();         jmsConn.close();
				}catch(Exception closeE) { }
			}			
		} catch (Exception e) { 
			e.printStackTrace(); 
		}
	}

	private static String processMessage(jakarta.jms.Message msg, java.sql.Connection dbConn) throws Exception
	{
		//Application specific DML Operation using dbConn

		return msg.getBody(String.class);
	}
}
