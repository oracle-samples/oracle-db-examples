/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.exception;

public class TravelAgencyException extends Exception {

    private static final long serialVersionUID = -9049819334831048239L;

    public TravelAgencyException(String message) {
        super(message);
    }

    public TravelAgencyException(String message, Throwable cause) {
        super(message, cause);
    }

}