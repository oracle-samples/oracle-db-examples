/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns.exception;

import org.springframework.http.HttpStatus;

public class APIException extends RuntimeException {
  private HttpStatus httpStatus;
  private String message;

  public APIException(HttpStatus httpsStatus, String message) {
    super(message);
    this.message = message;
    this.httpStatus = httpsStatus;
  }

  public HttpStatus getHttpStatus() {
    return httpStatus;
  }

  public String getMessage() {
    return message;
  }
}
