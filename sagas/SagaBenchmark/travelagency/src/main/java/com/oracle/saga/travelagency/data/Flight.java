/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.data;

import java.io.Serializable;
import java.util.List;
import java.util.Objects;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

public class Flight implements Serializable {
    private static final long serialVersionUID = -2591010130892357663L;
    private String action;
    private List<Passengers> passengers;

    /**
     * @return the action
     */
    public String getAction() {
        return action;
    }

    /**
     * @param action the action to set
     */
    public void setAction(String action) {
        this.action = action;
    }

    /**
     * @return the passengerList
     */
    public List<Passengers> getPassengers() {
        return passengers;
    }

    /**
     * @param passengerList the passengerList to set
     */
    public void setPassengers(List<Passengers> passengers) {
        this.passengers = passengers;
    }

    @Override
    public int hashCode() {
        return Objects.hash(action, passengers);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        Flight other = (Flight) obj;
        return Objects.equals(action, other.action) && Objects.equals(passengers, other.passengers);
    }

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

}
