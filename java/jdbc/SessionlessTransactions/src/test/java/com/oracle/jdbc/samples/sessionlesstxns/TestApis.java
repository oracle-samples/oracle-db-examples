/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns;

import com.oracle.jdbc.samples.sessionlesstxns.exception.PaymentFailedException;
import com.oracle.jdbc.samples.sessionlesstxns.service.PaymentService;
import org.junit.jupiter.api.*;
import org.mockito.Mockito;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpStatus;

public class TestApis extends TestBase {

  static final long FLIGHT1_ID = 0;
  static final int FLIGHT1_AVAILABLE_SEATS = 1;
  static final long FLIGHT1_PRICE = 1000;
  static final long FLIGHT2_ID = 1;
  static final long FLIGHT2_PRICE = 2300;
  static final long FLIGHT3_ID = 2;
  static final long PAYMENT_METHOD_ID = 0;
  static final String DUMMY_RECEIPT_NUMBER = "1442AZ";
  static final int DEFAULT_TIMEOUT = 1;

  @BeforeEach
  void updateData() {
    cleanTables();
    loadData();
  }

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
    Assertions.assertNotNull(jdbcTemplate.queryForObject(queryBookingOrder, Long.class, startTransaction.bookingId()));
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

  private void loadData() {
    runSQLScript("dataLoader.sql");
  }

  private void cleanTables() {
    runSQLScript("dataCleaner.sql");
  }
}
