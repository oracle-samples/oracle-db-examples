/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.data;

import java.io.Serializable;
import java.util.List;

public class SeatCountValidationCheck implements Serializable {
    private static final long serialVersionUID = -5918236855410483397L;
    private boolean allFlightSeatCountIsValid;
    private List<SeatValidationDetails> seatAvailability;

    /**
     * True if the seat counts for all the different seat types for the flight are the expected
     * value otherwise false.
     * 
     * @return the allFlightSeatCountIsValid
     */
    public boolean isAllFlightSeatCountIsValid() {
        return allFlightSeatCountIsValid;
    }

    /**
     * Sets true or false after determining whether the seat count for all the seat types on the
     * flight are valid.
     * 
     * @param allFlightSeatCountIsValid the allFlightSeatCountIsValid to set
     */
    public void setAllFlightSeatCountIsValid(boolean allFlightSeatCountIsValid) {
        this.allFlightSeatCountIsValid = allFlightSeatCountIsValid;
    }

    /**
     * Gets information about whether all the different seat types availiablity count is the
     * expected value by returning true or false for each of the respective seat type.
     * 
     * @return the seatAvailability
     */
    public List<SeatValidationDetails> getSeatAvailability() {
        return seatAvailability;
    }

    /**
     * @param seatAvailability the seatAvailability to set
     */
    public void setSeatAvailability(List<SeatValidationDetails> seatAvailability) {
        this.seatAvailability = seatAvailability;
    }

    /*
     * (non-Javadoc)
     * 
     * @see java.lang.Object#toString()
     */
    @Override
    public String toString() {
        return "SeatCountValidationCheck [allFlightSeatCountIsValid=" + allFlightSeatCountIsValid
                + ", seatAvailability=" + seatAvailability + "]";
    }

}
