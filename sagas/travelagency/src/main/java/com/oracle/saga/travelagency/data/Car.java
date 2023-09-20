/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.data;

import java.io.Serializable;
import java.util.Objects;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * The CarDto class contains the properties that will be set when renting a car.
 *
 */
public class Car implements Serializable {

    private static final long serialVersionUID = -70912058980500235L;
    private String action;
    private String customer;
    private String phone;
    private String driversLicense;
    private String birthdate;
    private String startDate;
    private String endDate;
    private String carType;

    /**
     * Get the action that is being performed by the travel agency.
     * 
     * @return The action to perform.
     */
    public String getAction() {
        return action;
    }

    /**
     * Set the action that is being performed by the travel agency. Currently "Booking" is the only
     * action being performed.
     * 
     * @param action A string implying the action to be performed.
     */
    public void setAction(String action) {
        this.action = action;
    }

    /**
     * Get the name of the customer renting the car.
     * 
     * @return Car customer's name.
     */
    public String getCustomer() {
        return customer;
    }

    /**
     * Sets the name of the customer renting the car.
     * 
     * @param customer The name of the customer renting the car.
     */
    public void setCustomer(String customer) {
        this.customer = customer;
    }

    /**
     * Gets the phone number of the customer renting the car.
     * 
     * @return The phone number of the customer renting the car.
     */
    public String getPhone() {
        return phone;
    }

    /**
     * Sets the phone number of the customer renting the car.
     * 
     * @param phone The phone number of the customer renting the car.
     */
    public void setPhone(String phone) {
        this.phone = phone;
    }

    /**
     * Gets the driver's license number of the customer renting the car.
     * 
     * @return The driver's license number of the customer renting the car.
     */
    public String getDriversLicense() {
        return driversLicense;
    }

    /**
     * Sets the driver's license number of the customer renting the car.
     * 
     * @param driversLicense The driver's license number of the customer renting the car.
     */
    public void setDriversLicense(String driversLicense) {
        this.driversLicense = driversLicense;
    }

    /**
     * Gets the birthdate of the customer renting the car.
     * 
     * @return The birthdate of the customer renting the car.
     */
    public String getBirthdate() {
        return birthdate;
    }

    /**
     * Sets the birthdate of the customer renting the car.
     * 
     * @param birthdate The birthdate of customer renting the car.
     */
    public void setBirthdate(String birthdate) {
        this.birthdate = birthdate;
    }

    /**
     * Gets the start date that the customer wants to rent the car for.
     * 
     * @return The start date of the car rental by the customer.
     */
    public String getStartDate() {
        return startDate;
    }

    /**
     * Sets the start date that the customer wants to rent the car for.
     * 
     * @param startDate The start date of the car rental by the customer.
     */
    public void setStartDate(String startDate) {
        this.startDate = startDate;
    }

    /**
     * Gets the end date that the customer wants to rent the car for.
     * 
     * @return The end date for the car rental by the customer.
     */
    public String getEndDate() {
        return endDate;
    }

    /**
     * Sets the end date that the customer wants to rent the car for.
     * 
     * @param endDate The end date for the car rental by the customer.
     */
    public void setEndDate(String endDate) {
        this.endDate = endDate;
    }

    /**
     * Gets the car type that the customer is renting.
     * 
     * @return The car type that the customer is renting.
     */
    public String getCarType() {
        return carType;
    }

    /**
     * Sets the car type that the customer is renting. The type of car can be one of the following
     * "COMPACT", "SUV", "VAN", "TRUCK", "LUXURY".
     * 
     * @param carType The car type that the customer is renting.
     */
    public void setCarType(String carType) {
        this.carType = carType;
    }

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

    @Override
    public int hashCode() {
        return Objects.hash(action, birthdate, carType, customer, driversLicense, endDate, phone,
                startDate);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if ((obj == null) || (getClass() != obj.getClass()))
            return false;
        Car other = (Car) obj;
        return Objects.equals(action, other.action) && Objects.equals(birthdate, other.birthdate)
                && Objects.equals(carType, other.carType)
                && Objects.equals(customer, other.customer)
                && Objects.equals(driversLicense, other.driversLicense)
                && Objects.equals(endDate, other.endDate) && Objects.equals(phone, other.phone)
                && Objects.equals(startDate, other.startDate);
    }

}
