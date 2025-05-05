package com.oracle.jdbc.samples.sessionlesstxns;

import com.oracle.jdbc.samples.sessionlesstxns.dto.CheckoutRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.CheckoutResponse;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RemoveTicketRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.StartTransactionRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RequestTicketsRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RequestTicketsResponse;
import com.oracle.jdbc.samples.sessionlesstxns.dto.StartTransactionResponse;
import com.oracle.jdbc.samples.sessionlesstxns.exception.PaymentFailedException;
import com.oracle.jdbc.samples.sessionlesstxns.service.PaymentService;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.*;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import javax.sql.DataSource;
import java.io.InputStream;
import java.util.List;
import java.util.Scanner;

@ActiveProfiles("test")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class TestApis {

  static final long FLIGHT1_ID = 0;
  static final int FLIGHT1_AVAILABLE_SEATS = 1;
  static final long FLIGHT1_PRICE = 1000;
  static final long FLIGHT2_ID = 1;
  static final long FLIGHT2_PRICE = 2300;
  static final long FLIGHT3_ID = 2;
  static final long PAYMENT_METHOD_ID = 0;
  static final String DUMMY_RECEIPT_NUMBER = "1442AZ";
  static final int DEFAULT_TIMEOUT = 1;

  static {
    RestAssured.baseURI = "http://127.0.0.1";
  }

  @LocalServerPort
  private int port;

  @BeforeAll
  void setUp() {
    RestAssured.port = port;
    createSchema();
  }

  @AfterAll
  void tearDown() {
    dropSchema();
  }

  @BeforeEach
  void updateData() {
    cleanTables();
    loadData();
  }

  @Autowired
  protected JdbcTemplate testJdbcTemplate;

  @Autowired
  protected DataSource dataSource;

  static protected PaymentService paymentService = Mockito.mock(PaymentService.class);

  @TestConfiguration
  static class TestConfig {
    @Bean
    @Primary
    public PaymentService paymentService() {
      return paymentService;
    }
  }

  /**
   * Test following scenario:
   *
   * 1. Start a transaction.
   * 2. Add 1 ticket of flight 1.
   * 3. Add 2 tickets of flight 2.
   * 4. Checkout.
   */
  @Test
  void testNormalScenario() {
    Mockito.when(paymentService.pay(Mockito.anyDouble(),Mockito.eq(PAYMENT_METHOD_ID)))
            .thenReturn(DUMMY_RECEIPT_NUMBER);

    final int FLIGHT1_REQUESTED_SEATS = 1;
    var startTransaction = testAPIStartTransaction(DEFAULT_TIMEOUT, FLIGHT1_ID, FLIGHT1_REQUESTED_SEATS, HttpStatus.CREATED);

    Assertions.assertNotNull(startTransaction);
    Assertions.assertNotNull(startTransaction.bookingId());
    Assertions.assertEquals(FLIGHT1_REQUESTED_SEATS, startTransaction.count());
    Assertions.assertEquals(FLIGHT1_REQUESTED_SEATS, startTransaction.seatIds().size());

    final int FLIGHT2_REQUESTED_SEATS = 2;
    var requestTickets = testAPIRequestTickets(
            startTransaction.transactionId(), FLIGHT2_ID, FLIGHT2_REQUESTED_SEATS, startTransaction.bookingId(), HttpStatus.CREATED);

    Assertions.assertNotNull(requestTickets);
    Assertions.assertEquals(FLIGHT2_REQUESTED_SEATS, requestTickets.count());
    Assertions.assertEquals(FLIGHT2_REQUESTED_SEATS, requestTickets.seatIds().size());

    var checkout = testAPICheckout(startTransaction.transactionId(), PAYMENT_METHOD_ID, startTransaction.bookingId(), HttpStatus.CREATED);

    Assertions.assertNotNull(checkout);
    Assertions.assertEquals(FLIGHT1_REQUESTED_SEATS * FLIGHT1_PRICE + FLIGHT2_REQUESTED_SEATS * FLIGHT2_PRICE, checkout.total());
    Assertions.assertEquals(PAYMENT_METHOD_ID, checkout.paymentMethod());
    Assertions.assertEquals(DUMMY_RECEIPT_NUMBER, checkout.receiptNumber());
    Assertions.assertNotNull(checkout.tickets());
    Assertions.assertEquals(FLIGHT1_REQUESTED_SEATS + FLIGHT2_REQUESTED_SEATS, checkout.tickets().size());

    final String queryBookingOrder = "SELECT id FROM bookings WHERE id = ?";
    Assertions.assertNotNull(testJdbcTemplate.queryForObject(queryBookingOrder, Long.class, startTransaction.bookingId()));
  }

  /**
   * Test following scenario:
   *  - Add 2 tickets of flight 1 (only one found)
   *  - Add 1 tickets of flight 3 (not free seat found)
   *  - cancel booking
   */
  @Test
  void secondScenario() {
    final int FLIGHT1_REQUESTED_SEATS = 2;
    var startTransaction = testAPIStartTransaction(DEFAULT_TIMEOUT, FLIGHT1_ID, FLIGHT1_REQUESTED_SEATS, HttpStatus.PARTIAL_CONTENT);

    Assertions.assertNotNull(startTransaction);
    Assertions.assertNotNull(startTransaction.bookingId());
    Assertions.assertEquals(FLIGHT1_AVAILABLE_SEATS, startTransaction.count());
    Assertions.assertEquals(FLIGHT1_AVAILABLE_SEATS, startTransaction.seatIds().size());

    final int FLIGHT3_REQUESTED_SEATS = 1;
    testAPIRequestTickets(startTransaction.transactionId(), FLIGHT3_ID, FLIGHT3_REQUESTED_SEATS, startTransaction.bookingId(), HttpStatus.NOT_FOUND);

    testAPICancelBooking(startTransaction.transactionId(), HttpStatus.OK);
  }

  /**
   * Test following scenario:
   *   - Request 2 seats of flight 2
   *   - Checkout (payment fails)
   *   - Remove ticket of flight 2
   *   - Checkout (payment succeeds)
   */
  @Test
  void thirdScenario() {
    Mockito.when(paymentService.pay(Mockito.anyDouble(),Mockito.eq(PAYMENT_METHOD_ID))).thenAnswer(invocation -> {
      double sum = invocation.getArgument(0);
      if (sum > FLIGHT2_PRICE) {
        throw new PaymentFailedException();
      }
      return DUMMY_RECEIPT_NUMBER;
    });

    final int FLIGHT2_REQUESTED_SEATS = 2;
    var startTransaction = testAPIStartTransaction(DEFAULT_TIMEOUT, FLIGHT2_ID, FLIGHT2_REQUESTED_SEATS, HttpStatus.CREATED);

    testAPICheckout(startTransaction.transactionId(), PAYMENT_METHOD_ID, startTransaction.bookingId(), HttpStatus.PAYMENT_REQUIRED);

    final long SEAT_ID_TO_CANCEL = startTransaction.seatIds().get(0);
    testAPIRemoveTicket(startTransaction.transactionId(), startTransaction.bookingId(), SEAT_ID_TO_CANCEL, HttpStatus.OK);

    final int NEW_REQUESTED_SEATS_COUNT = FLIGHT2_REQUESTED_SEATS - 1;
    var checkout = testAPICheckout(startTransaction.transactionId(), PAYMENT_METHOD_ID, startTransaction.bookingId(), HttpStatus.CREATED);

    Assertions.assertNotNull(checkout);
    Assertions.assertEquals(NEW_REQUESTED_SEATS_COUNT * FLIGHT2_PRICE, checkout.total());
    Assertions.assertEquals(DUMMY_RECEIPT_NUMBER, checkout.receiptNumber());
    Assertions.assertNotNull(checkout.tickets());
    Assertions.assertEquals(NEW_REQUESTED_SEATS_COUNT, checkout.tickets().size());
    Assertions.assertTrue(checkout.tickets().stream().noneMatch(ticket -> ticket.seatId().equals(SEAT_ID_TO_CANCEL)));
  }

  private void createSchema() {
    runSQLScript("createSchema.sql");
  }

  private void loadData() {
    runSQLScript("dataLoader.sql");
  }

  private void dropSchema() {
    runSQLScript("dropSchema.sql");
  }

  private void cleanTables() {
    runSQLScript("dataCleaner.sql");
  }

  private void runSQLScript(String fileName) {
    InputStream inputStream = getClass().getClassLoader().getResourceAsStream(fileName);
    List<String> instructions = new Scanner(inputStream).useDelimiter(";").tokens().toList();
    for (String sql : instructions) {
      testJdbcTemplate.update(sql);
    }
  }

  private StartTransactionResponse testAPIStartTransaction(int timeout, long flightId, int count, HttpStatus expectedStatus) {
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

  private RequestTicketsResponse testAPIRequestTickets(
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

  private void testAPIRemoveTicket(String transactionId, long bookingId, long seatId, HttpStatus expectedStatus) {
    RestAssured.given()
            .contentType(ContentType.JSON)
            .body(new RemoveTicketRequest(transactionId, seatId))
            .pathParams("bookingId", bookingId)
            .when()
            .delete("/api/v1/bookings/{bookingId}")
            .then()
            .statusCode(expectedStatus.value());
  }

  private CheckoutResponse testAPICheckout(
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

  private void testAPICancelBooking(String transactionId, HttpStatus expectedStatus) {
    RestAssured.given()
      .contentType(ContentType.JSON)
      .pathParam("transactionId", transactionId)
      .when()
      .post("/api/v1/bookings/cancel/{transactionId}")
      .then().statusCode(expectedStatus.value());
  }
}
