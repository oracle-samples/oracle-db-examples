/*
** Copyright (c) 2021 Oracle and/or its affiliates.
**
** The Universal Permissive License (UPL), Version 1.0
**
** Subject to the condition set forth below, permission is hereby granted to any
** person obtaining a copy of this software, associated documentation and/or data
** (collectively the "Software"), free of charge and under any and all copyright
** rights in the Software, and any and all patent rights owned or freely
** licensable by each licensor hereunder covering either (i) the unmodified
** Software as contributed to or provided by such licensor, or (ii) the Larger
** Works (as defined below), to deal in both
**
** (a) the Software, and
** (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
** one is included with the Software (each a "Larger Work" to which the Software
** is contributed by such licensors),
**
** without restriction, including without limitation the rights to copy, create
** derivative works of, display, perform, and distribute the Software and make,
** use, sell, offer for sale, import, export, have made, and have sold the
** Software and the Larger Work(s), and to sublicense the foregoing rights on
** either these or other terms.
**
** This license is subject to the following condition:
** The above copyright notice and either this complete permission notice or at
** a minimum a reference to the UPL must be included in all copies or
** substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
** SOFTWARE.
*/

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