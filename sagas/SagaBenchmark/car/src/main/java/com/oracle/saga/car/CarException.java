/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.car;

public class CarException extends Exception {

    private static final long serialVersionUID = 578698300409573742L;

    public CarException(String message) {
        super(message);
    }

    public CarException(String message, Throwable cause) {
        super(message, cause);
    }

}