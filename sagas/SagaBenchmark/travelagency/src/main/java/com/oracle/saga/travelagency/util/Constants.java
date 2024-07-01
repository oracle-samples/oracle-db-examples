/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.util;

/**
 * Contains a collection of defined constants.
 */
public final class Constants {

    private Constants() {
    }

    /**
     * Transaction State Types
     */
    public static final int TRANS_STARTED = 1;
    public static final int TRANS_COMPLETED = 2;
    public static final int TRANS_ERROR = 3;

    /**
     * Status Message Types
     */
    public static final int TRACE = 0;
    public static final int PERFORMANCE = 1;
    public static final int DEBUG = 2;
    public static final int ERROR = 3;

    /**
     * Error Messages
     */
    public static final String INVALID_RESULTSET_COUNT_FOR_FLIGHT_SEAT_VALIDATION = "The number of flights in the total booked seats per flight result set does not match flight seat difference per flight result set.";
    public static final String FLIGHTID_DO_NOT_MATCH = "The flight ID for checking the total booked seats per flight against the flight seat difference per flight do not match when traversing the respective result sets.";
    public static final String ERROR_CREATING_INITIAL_FLIGHT_TABLE = "The following error occurred while attempting to create the fligh table records: ";
}
