/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns.controller;

import com.oracle.jdbc.samples.sessionlesstxns.dto.CheckoutRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.CheckoutResponse;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RemoveTicketRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.StartTransactionRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RequestTicketsRequest;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RequestTicketsResponse;
import com.oracle.jdbc.samples.sessionlesstxns.dto.StartTransactionResponse;
import com.oracle.jdbc.samples.sessionlesstxns.service.BookingService;
import com.oracle.jdbc.samples.sessionlesstxns.service.PaymentService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

@CrossOrigin(originPatterns = "http://localhost:**")
@Controller
@RequestMapping("/api/v1/bookings")
public class BookingController {

    BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    /**
     * Start a new transaction, and request first flight ticket(s).
     */
    @PostMapping
    public ResponseEntity<StartTransactionResponse> startTransaction(@RequestBody StartTransactionRequest body) {

        StartTransactionResponse response = bookingService.startTransaction(body);

        if (body.count() > response.count()) {
            return new ResponseEntity<>(response, HttpStatus.PARTIAL_CONTENT);
        }

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * Resume transaction and request more tickets.
     */
    @PostMapping(value = {"/{bookingId}"})
    public ResponseEntity<RequestTicketsResponse> requestTickets(@PathVariable Long bookingId,
                                                                 @RequestBody RequestTicketsRequest body) {
        RequestTicketsResponse response = bookingService.requestTickets(bookingId, body);

        if (body.count() > response.count()) {
            return new ResponseEntity<>(response, HttpStatus.PARTIAL_CONTENT);
        }

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * Remove tickets from the booking order.
     */
    @DeleteMapping(value = {"/{bookingId}"})
    public ResponseEntity<Void> removeTicket(@PathVariable Long bookingId,
                                              @RequestBody RemoveTicketRequest body) {
        bookingService.removeTicket(bookingId, body.seatId(), body.transactionId());

        return new ResponseEntity<>(HttpStatus.OK);
    }

    /**
     * Pay and complete booking order.
     */
    @PostMapping(value = {"/{bookingId}/checkout"})
    public ResponseEntity<CheckoutResponse> checkout(@PathVariable Long bookingId,
                                                     @RequestBody CheckoutRequest body) {
        return new ResponseEntity<>(bookingService.checkout(bookingId, body), HttpStatus.CREATED);
    }

    /**
     * Cancel booking.
     */
    @PostMapping(value = {"/cancel/{transactionId}"})
    public ResponseEntity<Void> cancelBooking(@PathVariable String transactionId) {
        bookingService.cancelBooking(transactionId);

        return new ResponseEntity<>(HttpStatus.OK);
    }
}
