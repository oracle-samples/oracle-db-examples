/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns;

import com.oracle.jdbc.samples.sessionlesstxns.dto.CheckoutRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.CheckoutResponse;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RemoveTicketRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RequestTicketsRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RequestTicketsResponse;
import com.oracle.jdbc.samples.sessionlesstxns.dto.StartTransactionRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.StartTransactionResponse;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.Scanner;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class TestBase {
  static {
    RestAssured.baseURI = "http://127.0.0.1";
  }

  @LocalServerPort
  private int port;


  @Autowired
  protected JdbcTemplate jdbcTemplate;
  
  @BeforeAll
  void setUp() {
    RestAssured.port = port;
    createSchema();
  }
  
  @AfterAll
  void tearDown() {
    dropSchema();
  }

  public void runSQLScript(String fileName, String delimiter) {
    InputStream inputStream = TestBase.class.getClassLoader().getResourceAsStream(fileName);
    List<String> instructions = new Scanner(inputStream).useDelimiter(delimiter).tokens().toList();
    jdbcTemplate.batchUpdate(instructions.toArray(new String[0]));
  }

  public static StartTransactionResponse testAPIStartTransaction(int timeout, long flightId, int count, HttpStatus expectedStatus) {
    var request = RestAssured.given()
            .contentType(ContentType.JSON)
            .body(new StartTransactionRequest(timeout, flightId, count))
            .when()
            .post("/api/v1/bookings");

    if (expectedStatus.equals(HttpStatus.CREATED)  || expectedStatus.equals(HttpStatus.PARTIAL_CONTENT)) {
      return request
              .then()
              .statusCode(expectedStatus.value())
              .and()
              .extract()
              .response()
              .body().as(StartTransactionResponse.class);
    }

    request.then().statusCode(expectedStatus.value());
    return null;
  }

  public static RequestTicketsResponse testAPIRequestTickets(
          String transactionId, long flightId, int count, long bookingId, HttpStatus expectedStatus) {
    var request = RestAssured.given()
            .contentType(ContentType.JSON)
            .body(new RequestTicketsRequest(transactionId, flightId, count))
            .pathParam("bookingId", bookingId)
            .when()
            .post("/api/v1/bookings/{bookingId}");


    if (expectedStatus.equals(HttpStatus.CREATED) || expectedStatus.equals(HttpStatus.PARTIAL_CONTENT)) {
      return request
              .then()
              .statusCode(expectedStatus.value())
              .and()
              .extract()
              .response()
              .body().as(RequestTicketsResponse.class);
    }

    request.then().statusCode(expectedStatus.value());
    return null;
  }

  public void testAPIRemoveTicket(String transactionId, long bookingId, long seatId, HttpStatus expectedStatus) {
    RestAssured.given()
            .contentType(ContentType.JSON)
            .body(new RemoveTicketRequest(transactionId, seatId))
            .pathParams("bookingId", bookingId)
            .when()
            .delete("/api/v1/bookings/{bookingId}")
            .then()
            .statusCode(expectedStatus.value());
  }

  public static CheckoutResponse testAPICheckout(
          String transactionId, long paymentMethodId, long bookingId, HttpStatus expectedStatus) {
    var request = RestAssured.given()
            .contentType(ContentType.JSON)
            .body(new CheckoutRequest(transactionId, paymentMethodId))
            .pathParam("bookingId", bookingId)
            .when()
            .post("/api/v1/bookings/{bookingId}/checkout");

    if (expectedStatus.equals(HttpStatus.CREATED)) {
      return request
              .then()
              .statusCode(HttpStatus.CREATED.value())
              .and()
              .extract()
              .response()
              .body().as(CheckoutResponse.class);
    }

    request.then().statusCode(expectedStatus.value());
    return null;
  }

  public void testAPICancelBooking(String transactionId, HttpStatus expectedStatus) {
    RestAssured.given()
            .contentType(ContentType.JSON)
            .pathParam("transactionId", transactionId)
            .when()
            .post("/api/v1/bookings/cancel/{transactionId}")
            .then().statusCode(expectedStatus.value());
  }

  private void createSchema() {
    runSQLScript("createSchema.sql", ";/");
  }

  private void dropSchema() {
    runSQLScript("dropSchema.sql", ";");
  }
}
