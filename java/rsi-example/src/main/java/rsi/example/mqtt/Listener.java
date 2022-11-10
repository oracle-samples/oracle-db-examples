package rsi.example.mqtt;

import oracle.rsi.PushPublisher;
import oracle.rsi.ReactiveStreamsIngestion;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import org.fusesource.hawtbuf.Buffer;
import org.fusesource.hawtbuf.UTF8Buffer;
import org.fusesource.mqtt.client.*;
import rsi.example.common.Retailer;
import rsi.example.common.RSIService;

import java.io.ByteArrayInputStream;

public class Listener {
  private static final String ACTIVEMQ_HOST = "localhost";
  private static final int ACTIVEMQ_PORT = 1883;
  private static final String ACTIVEMQ_USER = "admin";
  private static final String ACTIVEMQ_PASSWORD = "password";
  private static final String DESTINATION = "/topic/event";
  private static final String TOPIC_NAME = "event";

  private static final String DB_URL = "jdbc:oracle:thin:@" +
      "(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=adb.us-phoenix-1.oraclecloud.com))(connect_data=(service_name=gebqqvpozhjbqbs_azuretestdb_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))";
  private static final String DB_USERNAME = "admin";
  private static final String DB_PASSWORD = "Example01*manager";

  private static final OracleJsonFactory JSON_FACTORY = new OracleJsonFactory();
  private static final RSIService RSI_SERVICE = new RSIService();

  public static void main(String[] args) throws Exception {
    // Setup ActiveMQ connection and consumer
    MQTT mqtt = new MQTT();
    mqtt.setHost(ACTIVEMQ_HOST, ACTIVEMQ_PORT);
    mqtt.setUserName(ACTIVEMQ_USER);
    mqtt.setPassword(ACTIVEMQ_PASSWORD);

    final CallbackConnection connection = mqtt.callbackConnection();
    connection.listener(new org.fusesource.mqtt.client.Listener() {
      long count = 0;
      long start = System.currentTimeMillis();

      PushPublisher<Retailer> pushPublisher;

      public void onConnected() {
        // Start up RSI
        RSI_SERVICE.setUrl(DB_URL);
        RSI_SERVICE.setUsername(DB_USERNAME);
        RSI_SERVICE.setPassword(DB_PASSWORD);
        RSI_SERVICE.setScheme(DB_USERNAME);
        RSI_SERVICE.setEntity(Retailer.class);
        ReactiveStreamsIngestion rsi = RSI_SERVICE.start();
        pushPublisher = ReactiveStreamsIngestion.pushPublisher();
        pushPublisher.subscribe(rsi.subscriber());
      }
      public void onDisconnected() {
        RSI_SERVICE.stop();
      }
      public void onFailure(Throwable value) {
        try {
          pushPublisher.close();
        } catch (Exception e) {
          e.printStackTrace();
        }
        RSI_SERVICE.stop();

        value.printStackTrace();
        System.exit(-2);
      }
      public void onPublish(UTF8Buffer topic, Buffer msg, Runnable ack) {
        String body = msg.utf8().toString();

        if (body.trim().equals("SHUTDOWN")) {
          long diff = System.currentTimeMillis() - start;
          System.out.println(String.format("Received %d in %.2f seconds", count, (1.0*diff/1000.0)));

          try {
            pushPublisher.close();
          } catch (Exception e) {
            e.printStackTrace();
          }
          RSI_SERVICE.stop();

          connection.disconnect(new Callback<Void>() {
            @Override
            public void onSuccess(Void value) {
              System.exit(0);
            }
            @Override
            public void onFailure(Throwable value) {
              value.printStackTrace();
              System.exit(-2);
            }
          });
        } else {
          OracleJsonObject jsonObject = JSON_FACTORY
              .createJsonTextValue(
                  new ByteArrayInputStream(body.getBytes()))
              .asJsonObject();

          // Push the data
//          pushPublisher.accept(new Retailer(jsonObject));

          if( count == 0 ) {
            start = System.currentTimeMillis();
          }
          if( count % 100 == 0 ) {
            System.out.println(String.format("Received %d messages.", count));
          }
          count ++;
        }
        ack.run();
      }
    });

    connection.connect(new Callback<Void>() {
      @Override
      public void onSuccess(Void value) {
        Topic[] topics = {new Topic(TOPIC_NAME, QoS.AT_LEAST_ONCE)};
        connection.subscribe(topics, new Callback<byte[]>() {
          public void onSuccess(byte[] qoses) {
          }
          public void onFailure(Throwable value) {
            value.printStackTrace();
            System.exit(-2);
          }
        });
      }
      @Override
      public void onFailure(Throwable value) {
        value.printStackTrace();
        System.exit(-2);
      }
    });

    // Wait forever..
    synchronized (Listener.class) {
      while(true)
        Listener.class.wait();
    }
  }
}

