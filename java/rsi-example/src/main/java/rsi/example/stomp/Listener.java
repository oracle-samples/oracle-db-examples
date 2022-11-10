package rsi.example.stomp;

import oracle.rsi.PushPublisher;
import oracle.rsi.ReactiveStreamsIngestion;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import org.fusesource.stomp.jms.StompJmsConnectionFactory;
import org.fusesource.stomp.jms.StompJmsDestination;
import org.fusesource.stomp.jms.message.StompJmsBytesMessage;
import rsi.example.common.Retailer;
import rsi.example.common.RSIService;

import javax.jms.*;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

public class Listener {
  private static final String ACTIVEMQ_HOST = "localhost";
  private static final int ACTIVEMQ_PORT = 61613;
  private static final String DESTINATION = "/topic/event";

  private static final String DB_URL = "jdbc:oracle:thin:@" +
      "(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=adb.us-phoenix-1.oraclecloud.com))(connect_data=(service_name=gebqqvpozhjbqbs_azuretestdb_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))";
  private static final String DB_USERNAME = "admin";
  private static final String DB_PASSWORD = "Example01*manager";

  private static final OracleJsonFactory JSON_FACTORY = new OracleJsonFactory();
  private static final RSIService RSI_SERVICE = new RSIService();

  public static void main(String[] args) throws Exception {
    StompJmsConnectionFactory factory = new StompJmsConnectionFactory();
    factory.setBrokerURI("tcp://" + ACTIVEMQ_HOST + ":" + ACTIVEMQ_PORT);

    Connection connection = factory.createConnection();
    connection.start();
    Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
    Destination dest = new StompJmsDestination(DESTINATION);

    MessageConsumer consumer = session.createConsumer(dest);

    long start = System.currentTimeMillis();
    long count = 1;

    // Start up RSI
    RSI_SERVICE.setUrl(DB_URL);
    RSI_SERVICE.setUsername(DB_USERNAME);
    RSI_SERVICE.setPassword(DB_PASSWORD);
    RSI_SERVICE.setScheme(DB_USERNAME);
    RSI_SERVICE.setEntity(Retailer.class);
    ReactiveStreamsIngestion rsi = RSI_SERVICE.start();
    PushPublisher<Retailer> pushPublisher = ReactiveStreamsIngestion.pushPublisher();
    pushPublisher.subscribe(rsi.subscriber());

    System.out.println("Waiting for messages...");
    while (true) {
      Message msg = consumer.receive();

      if (msg instanceof TextMessage || msg instanceof StompJmsBytesMessage) {
        String body = getBody(msg);
        if (body.trim().equals("SHUTDOWN")) {
          long diff = System.currentTimeMillis() - start;
          System.out.println(String.format("Received %d in %.2f seconds", count, (1.0 * diff / 1000.0)));

          // close RSI and worker threads
          pushPublisher.close();
          RSI_SERVICE.stop();
          break;

        } else {
          // Create OracleJsonObject from the incoming message
          OracleJsonObject jsonObject = JSON_FACTORY
              .createJsonTextValue(
                  new ByteArrayInputStream(body.getBytes()))
              .asJsonObject();

          // Push the data
          pushPublisher.accept(new Retailer(jsonObject));

          if (count == 0) {
            start = System.currentTimeMillis();
          }
          if (count % 1000 == 0) {
            System.out.println(String.format("Received %d messages.", count));
          }
          count++;
        }

      } else {
        System.out.println("Unexpected message type: " + msg.getClass());
      }
    }
    connection.close();
  }

  private static String getBody(Message msg) throws JMSException {
    if (msg instanceof TextMessage) {
      return ((TextMessage) msg).getText();

    } else if (msg instanceof StompJmsBytesMessage) {
      StompJmsBytesMessage stompMsg = (StompJmsBytesMessage)msg;

      byte bytesArray[] = new byte[(int) stompMsg.getBodyLength()];
      stompMsg.readBytes(bytesArray);
      return new String(bytesArray, StandardCharsets.UTF_8);

    } else {
      throw new IllegalArgumentException("Unexpected message type: " + msg.getClass());
    }
  }
}
