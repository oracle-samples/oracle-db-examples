/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.cloudbank.exception;

/**
 * CloudBankException is used to raise exception.
 */
public class CloudBankException extends Exception {

    public CloudBankException(String message) {
        super(message);
    }

    public CloudBankException(String message, Throwable cause) {
        super(message, cause);
    }

}