package com.example.demo;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Enumeration;
import java.util.Random;

import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.MessageProducer;
import javax.jms.Queue;
import javax.jms.QueueBrowser;
import javax.jms.QueueConnection;
import javax.jms.QueueConnectionFactory;
import javax.jms.QueueReceiver;
import javax.jms.QueueSession;
import javax.jms.Session;
import javax.jms.TextMessage;

import com.ClassicQueue.DTO.UserDetails;
import com.ClassicQueue.config.JsonUtils;

import oracle.AQ.AQException;
import oracle.AQ.AQQueueTable;
import oracle.AQ.AQQueueTableProperty;
import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.AQjmsDestination;
import oracle.jms.AQjmsDestinationProperty;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

public class DeliveryExample {

	static String username = "ADMIN";
	static String password = "MayankTayal1234";

	static String userQueueTable = "UserQueueTable";
	static String userQueueName = "UserQueueName";

	static String deliveryQueueTable = "deliveryQueueTable";
	static String deliveryQueueName = "deliveryQueueName";

	static String jdbcURL = "jdbc:oracle:thin:@aqlivelabtest_high?TNS_ADMIN=/Users/mayanktayal/Code/Database/Wallet_AQLivelabTest";

	private static String query = null;

	public static void main(String[] args) throws JMSException, AQException, SQLException, ClassNotFoundException {

		QueueConnectionFactory qcf = null;
		QueueConnection qconn = null;
		AQjmsSession qsession = null;
		Queue userQueue = null;
		Queue deliveryQueue = null;

		OracleDataSource ds = new OracleDataSource();
		ds.setUser(username);
		ds.setPassword(password);
		ds.setURL(jdbcURL);

		qcf = AQjmsFactory.getQueueConnectionFactory(ds);
		qconn = qcf.createQueueConnection(username, password);
		qsession = (AQjmsSession) qconn.createQueueSession(true, Session.AUTO_ACKNOWLEDGE);
		qconn.start();

		userQueue = setup(qsession, username, userQueueTable, userQueueName);
		deliveryQueue = setup(qsession, username, deliveryQueueTable, deliveryQueueName);
		System.out.println("Setup is complete");

		// Step 1: Enqueue user
		Random rnd = new Random();
		int otp = rnd.nextInt(9999);
		int orderId = rnd.nextInt(999);

		UserDetails userDetails = new UserDetails(orderId, "Mayank", otp, "Pending", "US");
		String query = "insert into USERDETAILS values('" + orderId + "', '" + userDetails.getUsername() + "', '" + otp
				+ "', '" + userDetails.getDeliveryStatus() + "', '" + userDetails.getDeliveryLocation() + "')";
		databaseOperations(query);
		enqueueMessages(qsession, userQueue, userDetails);
		System.out.println("Step 1: Enqueue user is complete");

		// Step 2: Enqueue delivery boy
		UserDetails deliveryDetails = new UserDetails(userDetails.getOrderId(), null, 0,
				userDetails.getDeliveryStatus(), userDetails.getDeliveryLocation());
		enqueueMessages(qsession, deliveryQueue, deliveryDetails);
		System.out.println("Step 2: Enqueue delivery boy is complete");

		// Step 3: Dequeue User
		System.out.println("Step 3: Dequeue user initiated");
		dequeueMessages(qsession, username, userQueue, deliveryQueue, userDetails, deliveryDetails);
		System.out.println("All dequeue is complete");

		cleanup(qsession, username);
		qsession.close();
		qconn.close();
		System.out.println("End of Delivery");
	}

	public static Queue setup(QueueSession session, String username, String queueTable, String queueName)
			throws JMSException, AQException {
		AQQueueTableProperty qtprop = null;
		AQQueueTable qtable = null;
		AQjmsDestinationProperty dprop = null;
		Queue queue = null;

		try {
			qtable = ((AQjmsSession) session).getQueueTable(username, queueTable);
			if (qtable != null)
				qtable.drop(true);
		} catch (Exception e) {
		}

		qtprop = new AQQueueTableProperty("SYS.ANYDATA");
		qtprop.setMultiConsumer(false);
		qtprop.setCompatible("9.2.0.0.0");
		qtable = ((AQjmsSession) session).createQueueTable(username, queueTable, qtprop);

		dprop = new AQjmsDestinationProperty();
		queue = ((AQjmsSession) session).createQueue(qtable, queueName, dprop);
		System.out.println("Created queue queueName");
		((AQjmsDestination) queue).start(session, true, true);

		return queue;
	}

	public static void enqueueMessages(QueueSession session, Queue queue, UserDetails user)
			throws JMSException, java.sql.SQLException {
		TextMessage adt_message = null;
		MessageProducer producer = session.createProducer(queue);
		adt_message = ((AQjmsSession) session).createTextMessage();
		String msg = JsonUtils.writeValueAsString(user);
		adt_message.setText(msg);
		producer.send(adt_message);
		System.out.println("Sent AdtMessage");

		session.commit();
		producer.close();
		// QueueSender sender = session.createSender(queue);
		// sender.send(adt_message);
		// sender.close();
	}

	public static void dequeueMessages(QueueSession session, String username, Queue userQueue, Queue deliveryQueue,
			UserDetails userData, UserDetails deliveryData)
			throws JMSException, java.lang.ClassNotFoundException, java.sql.SQLException {

		QueueReceiver userReceiver = null;
		QueueReceiver deliveryReceiver = null;
		QueueReceiver appReceiver = null;

		Message userMessage = null;
		Message deliveryMessage = null;

		// Step 4: Dequeue browse for user
		QueueBrowser userBrowser = session.createBrowser(userQueue);
		Enumeration userEnum = userBrowser.getEnumeration();
		while (userEnum.hasMoreElements()) {
			userMessage = (TextMessage) userEnum.nextElement();
		}
		System.out.println("Step 4: Dequeue Browse for user: [" + ((TextMessage) userMessage).getText() + "]");

		UserDetails userDetails = JsonUtils.read(((TextMessage) userMessage).getText(), UserDetails.class);

		// Step 5: Enqueue for app
		deliveryData.setOtp(userDetails.getOtp());
		enqueueMessages(session, deliveryQueue, deliveryData);
		System.out.println("Step 5: Enqueue Browse for app: ");

		// Step 6: Dequeue browse by app
		QueueBrowser deliveryBrowser = session.createBrowser(deliveryQueue);
		Enumeration deliveryEnum = deliveryBrowser.getEnumeration();
		while (deliveryEnum.hasMoreElements()) {
			deliveryMessage = (TextMessage) deliveryEnum.nextElement();
		}
		System.out.println("Step 6: Dequeue Browse by app:  [" + ((TextMessage) deliveryMessage).getText() + "]");

		UserDetails deliveryDetails = JsonUtils.read(((TextMessage) deliveryMessage).getText(), UserDetails.class);
		query = "UPDATE USERDETAILS set Delivery_Status = 'DELIVERED' WHERE ORDERID = '" + deliveryDetails.getOrderId()
				+ "' AND OTP = '" + deliveryDetails.getOtp() + "'";

		// Step 7: Match user OTP and app OTP
		if (userDetails.getOtp() == deliveryDetails.getOtp()) {
			System.out.println("Step 7: OTP matched" + userDetails.getOtp() + " == " + deliveryDetails.getOtp());

			// Step 8: dequeue remove
			userReceiver = session.createReceiver(userQueue);
			TextMessage userMsg = (TextMessage) userReceiver.receive();
			System.out.println("Dequeue user receiver: " + userMsg.getText());

			deliveryReceiver = session.createReceiver(deliveryQueue);
			TextMessage deliveryMsg = (TextMessage) deliveryReceiver.receive();
			System.out.println("Dequeue delivery receiver: " + deliveryMsg.getText());

			appReceiver = session.createReceiver(deliveryQueue);
			TextMessage appMsg = (TextMessage) appReceiver.receive();
			System.out.println("Dequeue app receiver: " + appMsg.getText());

			System.out.println("Step 8: Dequeue all receiver");

			// Step 9: Update DB
			query = "UPDATE USERDETAILS set Delivery_Status = 'DELIVERED' WHERE ORDERID = '"
					+ deliveryDetails.getOrderId() + "' AND OTP = '" + deliveryDetails.getOtp() + "'";
			databaseOperations(query);
			System.out.println("Step 9: Update Delivery Status as DELIVERED in DB");

		} else {
			// Step 9: Update DB
			query = "UPDATE USERDETAILS set Delivery_Status = 'FAILED' WHERE ORDERID = '" + deliveryDetails.getOrderId()
					+ "' AND OTP = '" + deliveryDetails.getOtp() + "'";
			databaseOperations(query);
			System.out.println("Step 9: Update Delivery Status as FAILED in DB");

		}
		userBrowser.close();
		deliveryBrowser.close();

		userReceiver.close();
		deliveryReceiver.close();
		appReceiver.close();

		session.commit();
	}

	private static void cleanup(QueueSession session, String user) throws JMSException, AQException {

		AQQueueTable userTable = ((AQjmsSession) session).getQueueTable(user, userQueueTable);
		AQQueueTable deliveryTable = ((AQjmsSession) session).getQueueTable(user, deliveryQueueTable);

		if (userTable != null && deliveryTable != null) {
			userTable.drop(true);
			deliveryTable.drop(true);
			System.out.println("Queue tables dropped successfully");
		} else {
			System.out.println("Queue tables dropped failed");
		}
	}

	public static void databaseOperations(String queryData) throws ClassNotFoundException, SQLException {
		Class.forName("oracle.jdbc.driver.OracleDriver");
		Connection con = DriverManager.getConnection(jdbcURL, username, password);
		Statement stmt = con.createStatement();

		int x = stmt.executeUpdate(queryData);
		if (x > 0) {
			System.out.println("Successfully executed database operation");
		} else {
			System.out.println("Failed database operation");
		}
		con.close();
	}
}
