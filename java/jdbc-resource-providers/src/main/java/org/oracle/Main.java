package org.oracle;

import java.sql.*;

public class Main {
  public static void main(String[] args) {

    // Retrieve credentials, if needed
    // comment out if username, password not required
    String PASSWORD = System.getenv("ORACLE_PASSWORD");
    String USERNAME = System.getenv("ORACLE_USERNAME");
    // Set custom location for the config properties file with the property oracle.jdbc.config.file
    System.setProperty("oracle.jdbc.config.file", "properties/demo-1.properties");

    // try-with: establish a connection and retrieve database version
    // remove arguments if USERNAME, PASSWORD not required
    try (Connection connection = DriverManager.getConnection("jdbc:oracle:thin:@", USERNAME, PASSWORD);
      PreparedStatement ps = connection.prepareStatement("select BANNER from v$version");
      ResultSet rs = ps.executeQuery()
    ) {
      rs.next();
      System.out.println(rs.getString("BANNER"));

    } catch (SQLException e) {
      throw new RuntimeException(e);
    }

  }
}