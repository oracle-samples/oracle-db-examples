/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.airline;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CompensationData implements Serializable {
    private static final long serialVersionUID = -7073233007590700351L;
    private String sagaId;
    private List<Integer> personIdList = new ArrayList<>();
    private Map<Integer, List<String>> trackFlightSeatTypesBooked = new HashMap<>();

    /**
     * @return the trackFlightSeatTypesBooked
     */
    public Map<Integer, List<String>> getTrackFlightSeatTypesBooked() {
        return trackFlightSeatTypesBooked;
    }

    /**
     * @param trackFlightSeatTypesBooked the trackFlightSeatTypesBooked to set
     */
    public void setTrackFlightSeatTypesBooked(
            Map<Integer, List<String>> trackFlightSeatTypesBooked) {
        this.trackFlightSeatTypesBooked = trackFlightSeatTypesBooked;
    }

    public String getSagaId() {
        return sagaId;
    }

    public void setSagaId(String sagaId) {
        this.sagaId = sagaId;
    }

    public List<Integer> getPersonIdList() {
        return personIdList;
    }

    public void setPersonIdList(List<Integer> personIdList) {
        this.personIdList = personIdList;
    }

    /*
     * (non-Javadoc)
     * 
     * @see java.lang.Object#toString()
     */

    @Override
    public String toString() {
        return "CompensationData [personIdList=" + personIdList + ", sagaId=" + sagaId
                + ", trackFlightSeatTypesBooked=" + trackFlightSeatTypesBooked + "]";
    }
}
