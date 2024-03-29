/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.banka.data;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * CreditResponse is class which is used to store accountNumber and creditLimit for newly created Credit Cards.
 */
public class CreditResponse {

    private String accountNumber;
    private String creditLimit;
    

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

    /**
     * @return String return the accountNumber
     */
    public String getAccountNumber() {
        return accountNumber;
    }

    /**
     * @param accountNumber the accountNumber to set
     */
    public void setAccountNumber(String accountNumber) {
        this.accountNumber = accountNumber;
    }

    /**
     * @return String return the creditLimit
     */
    public String getCreditLimit() {
        return creditLimit;
    }

    /**
     * @param creditLimit the creditLimit to set
     */
    public void setCreditLimit(String creditLimit) {
        this.creditLimit = creditLimit;
    }

}