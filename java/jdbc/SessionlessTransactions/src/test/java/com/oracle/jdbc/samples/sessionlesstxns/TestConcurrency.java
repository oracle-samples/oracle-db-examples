/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns;


import com.oracle.jdbc.samples.sessionlesstxns.service.PaymentService;
import org.junit.jupiter.api.*;
import org.mockito.Mockito;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class TestConcurrency extends TestBase {

  private static final Logger logger = LoggerFactory.getLogger(TestConcurrency.class);

  static final long FLIGHT1_ID = 0;
  static final long FLIGHT1_PRICE = 1000;
  static final long PAYMENT_METHOD_ID = 0;
  static final String DUMMY_RECEIPT_NUMBER = "1442AZ";
  static final int DEFAULT_TIMEOUT = 1;

  @BeforeEach
  void updateData() {
    cleanTables();
    loadData();
    Mockito.when(paymentService.pay(Mockito.anyDouble(),Mockito.eq(PAYMENT_METHOD_ID)))
            .thenReturn(DUMMY_RECEIPT_NUMBER);
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

  @Test
  void testNormalScenario() {
    Runnable test = () -> {
      try {
        testScenario();
      } catch (InterruptedException e) {
        throw new RuntimeException(e);
      }
    };

    long start = System.currentTimeMillis();

    final int numberOfExecutions = 50;
    try (ExecutorService exService = Executors.newFixedThreadPool(numberOfExecutions)) {
      List<Future<?>> futures = new ArrayList<>();
      for (int i = 0; i < numberOfExecutions; i++) {
        futures.add(exService.submit(test));
      }
      // Wait for all tasks to complete
      for (Future<?> future : futures) {
        try {
          future.get(); // This blocks until the task completes
        } catch (InterruptedException | ExecutionException e) {
          logger.error("Task execution failed", e);
        }
      }
    }

    logger.info("Execution time: {} s", (System.currentTimeMillis() - start) / 1_000);
  }

  void testScenario() throws InterruptedException {
    final int REQUESTED_SEATS1 = 1;
    var startTransaction = testAPIStartTransaction(DEFAULT_TIMEOUT, FLIGHT1_ID, REQUESTED_SEATS1, HttpStatus.CREATED);

    Assertions.assertNotNull(startTransaction);
    Assertions.assertNotNull(startTransaction.bookingId());
    Assertions.assertEquals(REQUESTED_SEATS1, startTransaction.count());
    Assertions.assertEquals(REQUESTED_SEATS1, startTransaction.seatIds().size());

    Thread.sleep(1000);
    final int REQUESTED_SEATS2 = 1;
    var requestTickets = testAPIRequestTickets(
            startTransaction.transactionId(), FLIGHT1_ID, REQUESTED_SEATS2, startTransaction.bookingId(), HttpStatus.CREATED);

    Assertions.assertNotNull(requestTickets);
    Assertions.assertEquals(REQUESTED_SEATS2, requestTickets.count());
    Assertions.assertEquals(REQUESTED_SEATS2, requestTickets.seatIds().size());

    Thread.sleep(1000);
    var checkout = testAPICheckout(startTransaction.transactionId(), PAYMENT_METHOD_ID, startTransaction.bookingId(), HttpStatus.CREATED);

    Assertions.assertNotNull(checkout);
    Assertions.assertEquals(REQUESTED_SEATS1 * FLIGHT1_PRICE + REQUESTED_SEATS2 * FLIGHT1_PRICE, checkout.total());
    Assertions.assertEquals(PAYMENT_METHOD_ID, checkout.paymentMethod());
    Assertions.assertEquals(DUMMY_RECEIPT_NUMBER, checkout.receiptNumber());
    Assertions.assertNotNull(checkout.tickets());
    Assertions.assertEquals(REQUESTED_SEATS1 + REQUESTED_SEATS2, checkout.tickets().size());

    final String queryBookingOrder = "SELECT id FROM bookings WHERE id = ?";
    Assertions.assertNotNull(jdbcTemplate.queryForObject(queryBookingOrder, Long.class, startTransaction.bookingId()));
  }

  private void loadData() {
    runSQLScript("hundredsSeats.sql", ";");
  }

  private void cleanTables() {
    runSQLScript("dataCleaner.sql", ";");
  }
}
