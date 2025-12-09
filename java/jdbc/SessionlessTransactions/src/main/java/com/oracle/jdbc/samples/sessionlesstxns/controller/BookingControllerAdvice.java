/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns.controller;

import com.oracle.jdbc.samples.sessionlesstxns.dto.ErrorResponse;
import com.oracle.jdbc.samples.sessionlesstxns.exception.APIException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class BookingControllerAdvice {
    @ExceptionHandler({APIException.class})
    public ResponseEntity<ErrorResponse> handleAPIException(APIException ex) {
        ErrorResponse errorResponse = new ErrorResponse(
                ex.getHttpStatus().value(),
                ex.getHttpStatus().name(),
                ex.getMessage());

        return new ResponseEntity<>(errorResponse, ex.getHttpStatus());
    }
}
