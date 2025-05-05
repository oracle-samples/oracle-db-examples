/*
 * Copyright (c) 2024 Oracle and/or its affiliates.
 *
 * The Universal Permissive License (UPL), Version 1.0
 *
 * Subject to the condition set forth below, permission is hereby granted to any
 * person obtaining a copy of this software, associated documentation and/or data
 * (collectively the "Software"), free of charge and under any and all copyright
 * rights in the Software, and any and all patent rights owned or freely
 * licensable by each licensor hereunder covering either (i) the unmodified
 * Software as contributed to or provided by such licensor, or (ii) the Larger
 * Works (as defined below), to deal in both
 *
 * (a) the Software, and
 * (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
 * one is included with the Software (each a "Larger Work" to which the Software
 * is contributed by such licensors),
 *
 * without restriction, including without limitation the rights to copy, create
 * derivative works of, display, perform, and distribute the Software and make,
 * use, sell, offer for sale, import, export, have made, and have sold the
 * Software and the Larger Work(s), and to sublicense the foregoing rights on
 * either these or other terms.
 *
 * This license is subject to the following condition:
 * The above copyright notice and either this complete permission notice or at
 * a minimum a reference to the UPL must be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
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
