/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.creditscore.exception;

/**
 * CreditScoreException is used to raise exception.
 */
public class CreditScoreException extends Exception {


    public CreditScoreException(String message) {
        super(message);
    }

    public CreditScoreException(String message, Throwable cause) {
        super(message, cause);
    }

}