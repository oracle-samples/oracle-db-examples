/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns.exception;

import org.springframework.http.HttpStatus;

public class TransactionNotFoundException extends APIException {

  public TransactionNotFoundException(String transaction_id) {
    super(HttpStatus.NOT_FOUND, "Transaction " + transaction_id + " not found");
  }
}
