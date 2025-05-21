/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns.exception;

import org.springframework.http.HttpStatus;

public class UnexpectedException extends APIException {
  public UnexpectedException(Throwable cause) {
    super(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error has occurred");
    initCause(cause);
  }
}
