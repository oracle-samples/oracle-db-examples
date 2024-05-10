/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.data;

import java.io.Serializable;

public class SeatValidationDetails implements Serializable {

    private static final long serialVersionUID = 384603016416719272L;
    private String databaseUrl;
    private int flightId;
    private boolean isAvailableEconomyValid;
    private boolean isAvailableBussinessValid;
    private boolean isAvailiableFirstClassValid;
    private int economyTotal;
    private int economyDiff;
    private int businessTotal;
    private int businessDiff;
    private int firstClassTotal;
    private int firstClassDiff;

    /**
     * Get the database URL.
     * 
     * @return The database URL
     */
    public String getDatabaseUrl() {
        return databaseUrl;
    }

    /**
     * Sets the database URL.
     * 
     * @param databaseUrl
     */
    public void setDatabaseUrl(String databaseUrl) {
        this.databaseUrl = databaseUrl;
    }

    /**
     * Get the flight Id.
     * 
     * @return the flightId
     */
    public int getFlightId() {
        return flightId;
    }

    /**
     * Sets the flight Id.
     * 
     * @param flightId the flightId to set
     */
    public void setFlightId(int flightId) {
        this.flightId = flightId;
    }

    /**
     * True if the available economy seat count is determined to be the expected value after the
     * test run, otherwise false.
     * 
     * @return the isAvailableEconomyValid
     */
    public boolean isAvailableEconomyValid() {
        return isAvailableEconomyValid;
    }

    /**
     * Sets the boolean flag for the available economy seats once the value has been determined to
     * be true or false.
     * 
     * @param isAvailableEconomyValid the isAvailableEconomyValid to set
     */
    public void setAvailableEconomyValid(boolean isAvailableEconomyValid) {
        this.isAvailableEconomyValid = isAvailableEconomyValid;
    }

    /**
     * True if the available business seat count is determined to be the expected value after the
     * test run, otherwise false.
     * 
     * @return the isAvailableBussinessValid
     */
    public boolean isAvailableBussinessValid() {
        return isAvailableBussinessValid;
    }

    /**
     * Sets the boolean flag for the available business seats once the value has been determined to
     * be true or false.
     * 
     * @param isAvailableBussinessValid the isAvailableBussinessValid to set
     */
    public void setAvailableBussinessValid(boolean isAvailableBussinessValid) {
        this.isAvailableBussinessValid = isAvailableBussinessValid;
    }

    /**
     * True if the available first class seat count is determined to be the expected value after the
     * test run, otherwise false.
     * 
     * @return the isAvailiableFirstClassValid
     */
    public boolean isAvailiableFirstClassValid() {
        return isAvailiableFirstClassValid;
    }

    /**
     * Sets the boolean flag for the available first class seats once the value has been determined
     * to be true or false.
     * 
     * @param isAvailiableFirstClassValid the isAvailiableFirstClassValid to set
     */
    public void setAvailiableFirstClassValid(boolean isAvailiableFirstClassValid) {
        this.isAvailiableFirstClassValid = isAvailiableFirstClassValid;
    }

    public int getEconomyTotal() {
        return economyTotal;
    }

    public void setEconomyTotal(int economyTotal) {
        this.economyTotal = economyTotal;
    }

    public int getEconomyDiff() {
        return economyDiff;
    }

    public void setEconomyDiff(int economyDiff) {
        this.economyDiff = economyDiff;
    }

    public int getBusinessTotal() {
        return businessTotal;
    }

    public void setBusinessTotal(int businessTotal) {
        this.businessTotal = businessTotal;
    }

    public int getBusinessDiff() {
        return businessDiff;
    }

    public void setBusinessDiff(int businessDiff) {
        this.businessDiff = businessDiff;
    }

    public int getFirstClassTotal() {
        return firstClassTotal;
    }

    public void setFirstClassTotal(int firstClassTotal) {
        this.firstClassTotal = firstClassTotal;
    }

    public int getFirstClassDiff() {
        return firstClassDiff;
    }

    public void setFirstClassDiff(int firstClassDiff) {
        this.firstClassDiff = firstClassDiff;
    }

    /*
     * (non-Javadoc)
     * 
     * @see java.lang.Object#toString()
     */

    @Override
    public String toString() {
        return "SeatValidationDetails [databaseUrl=" + databaseUrl + ", flightId=" + flightId
                + ", isAvailableEconomyValid=" + isAvailableEconomyValid
                + ", isAvailableBussinessValid=" + isAvailableBussinessValid
                + ", isAvailiableFirstClassValid=" + isAvailiableFirstClassValid + ", economyTotal="
                + economyTotal + ", economyDiff=" + economyDiff + ", businessTotal=" + businessTotal
                + ", businessDiff=" + businessDiff + ", firstClassTotal=" + firstClassTotal
                + ", firstClassDiff=" + firstClassDiff + "]";
    }

}
