/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.bankb.exception;

/**
 * AccountsException is used to raise exception.
 */
public class AccountsException extends Exception {
    
    public AccountsException(String message) {
        super(message);
    }

    public AccountsException(String message, Throwable cause) {
        super(message, cause);
    }

}