/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.banka.data;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.Serializable;

/**
 * CompensationData is a class used to store saga compensation objects in cache.
 */
public class CompensationData implements Serializable {
    private String sagaId;
    private String ucid;

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

    public String getOperationtype() {
        return operationtype;
    }

    public void setOperationtype(String operationtype) {
        this.operationtype = operationtype;
    }

    private String operationtype;
    private String accountnumber;

    public String getAccountnumber() {
        return accountnumber;
    }

    public void setAccountnumber(String accountnumber) {
        this.accountnumber = accountnumber;
    }


    /**
     * Gets the saga id created when the transaction was initiated by the Oraorder.
     * 
     * @return the sagaId
     */
    public String getSagaId() {
        return sagaId;
    }

    /**
     * Sets the saga id created when the transaction was initiated by the oraorder.
     * 
     * @param sagaId the sagaId to set
     */
    public void setSagaId(String sagaId) {
        this.sagaId = sagaId;
    }

    /**
     * @return String return the ucid
     */
    public String getUcid() {
        return ucid;
    }

    /**
     * @param ucid the ucid to set
     */
    public void setUcid(String ucid) {
        this.ucid = ucid;
    }

}
