package com.oracle.healthcheck;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.net.ssl.HttpsURLConnection;

import com.sun.net.httpserver.HttpServer;

import oracle.jdbc.internal.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

public class Client {

  public static void main(String[] args)
      throws SQLException, IOException {

    // Retrieve user credentials from environment variables.
    // They are set in the Pod from a Secret in src/main/k8s/app.yaml
    OracleDataSource ds = new OracleDataSource();
    ds.setURL(System.getenv("url"));
    ds.setUser(System.getenv("user"));
    ds.setPassword(System.getenv("password"));

    // Validate and log connection
    OracleConnection connection = (OracleConnection) ds.getConnection();
    System.out.println("Retrieving connections: " + connection.isValid(0));
    System.out
        .println("Database version: "
            + connection.getMetaData().getDatabaseMajorVersion() + "."
            + connection.getMetaData().getDatabaseMinorVersion());
    
    // Start an HttpServer listening on port 8080 to send database status.
    HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
    server.createContext("/", (httpExchange) -> {

      try (OracleConnection conn = (OracleConnection) ds.getConnection();
          Statement stmt = conn.createStatement()) {

        // Database message: version and sysdate
        ResultSet rs = stmt.executeQuery("select SYSDATE from dual");
        rs.next();

        String message = "{\"database-version\": \""
            + conn.getMetaData().getDatabaseMajorVersion() + "."
            + conn.getMetaData().getDatabaseMinorVersion()
            + "\", \"database-sysdate\": \"" + rs.getString(1) + "\"}";
        System.out.println(message);

        // Send message, status and flush
        httpExchange
            .sendResponseHeaders(HttpsURLConnection.HTTP_OK, message.length());
        OutputStream os = httpExchange.getResponseBody();
        os.write(message.getBytes());
        os.close();

      } catch (SQLException e) {
        e.printStackTrace();
      }
    });

    server.setExecutor(null);
    server.start();
  }
}