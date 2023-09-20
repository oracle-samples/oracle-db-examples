/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.data;

import java.io.Serializable;
import java.util.Objects;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

public class Passengers implements Serializable {

    private static final long serialVersionUID = 1787462885379570798L;
    private String firstName;
    private String lastName;
    private String middleName;
    private String birthdate;
    private String gender;
    private String email;
    private String phonePrimary;
    private String flightId;
    private String seatType;
    private String seatNumber;

    /**
     * @return the firstName
     */
    public String getFirstName() {
        return firstName;
    }

    /**
     * @param firstName the firstName to set
     */
    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    /**
     * @return the lastName
     */
    public String getLastName() {
        return lastName;
    }

    /**
     * @param lastName the lastName to set
     */
    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    /**
     * @return the middleName
     */
    public String getMiddleName() {
        return middleName;
    }

    /**
     * @param middleName the middleName to set
     */
    public void setMiddleName(String middleName) {
        this.middleName = middleName;
    }

    /**
     * @return the birthdate
     */
    public String getBirthdate() {
        return birthdate;
    }

    /**
     * @param birthdate the birthdate to set
     */
    public void setBirthdate(String birthdate) {
        this.birthdate = birthdate;
    }

    /**
     * @return the gender
     */
    public String getGender() {
        return gender;
    }

    /**
     * @param gender the gender to set
     */
    public void setGender(String gender) {
        this.gender = gender;
    }

    /**
     * @return the email
     */
    public String getEmail() {
        return email;
    }

    /**
     * @param email the email to set
     */
    public void setEmail(String email) {
        this.email = email;
    }

    /**
     * @return the phonePrimary
     */
    public String getPhonePrimary() {
        return phonePrimary;
    }

    /**
     * @param phonePrimary the phonePrimary to set
     */
    public void setPhonePrimary(String phonePrimary) {
        this.phonePrimary = phonePrimary;
    }

    /**
     * @return the flightId
     */
    public String getFlightId() {
        return flightId;
    }

    /**
     * @param flightId the flightId to set
     */
    public void setFlightId(String flightId) {
        this.flightId = flightId;
    }

    /**
     * @return the seatType
     */
    public String getSeatType() {
        return seatType;
    }

    /**
     * @param seatType the seatType to set
     */
    public void setSeatType(String seatType) {
        this.seatType = seatType;
    }

    /**
     * @return the seatNumber
     */
    public String getSeatNumber() {
        return seatNumber;
    }

    /**
     * @param seatNumber the seatNumber to set
     */
    public void setSeatNumber(String seatNumber) {
        this.seatNumber = seatNumber;
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
        return Objects.hash(birthdate, email, firstName, flightId, gender, lastName, middleName,
                phonePrimary, seatNumber, seatType);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        Passengers other = (Passengers) obj;
        return Objects.equals(birthdate, other.birthdate) && Objects.equals(email, other.email)
                && Objects.equals(firstName, other.firstName)
                && Objects.equals(flightId, other.flightId) && Objects.equals(gender, other.gender)
                && Objects.equals(lastName, other.lastName)
                && Objects.equals(middleName, other.middleName)
                && Objects.equals(phonePrimary, other.phonePrimary)
                && Objects.equals(seatNumber, other.seatNumber)
                && Objects.equals(seatType, other.seatType);
    }

}
