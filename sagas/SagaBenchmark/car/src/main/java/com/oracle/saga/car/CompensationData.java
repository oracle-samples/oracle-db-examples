/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.car;

import java.io.Serializable;

public class CompensationData implements Serializable {
    private static final long serialVersionUID = 7725334161374585020L;
    private String sagaId;
    private int customerId;

    /**
     * Gets the saga id created when the transaction was initiated by the travelagency.
     * 
     * @return the sagaId
     */
    public String getSagaId() {
        return sagaId;
    }

    /**
     * Sets the saga id created when the transaction was initiated by the travelagency.
     * 
     * @param sagaId the sagaId to set
     */
    public void setSagaId(String sagaId) {
        this.sagaId = sagaId;
    }

    /**
     * Gets the customer id created when the rental was processed.
     * 
     * @return the customerId
     */
    public int getCustomerId() {
        return customerId;
    }

    /**
     * Sets the customer id created when the rental was processed.
     * 
     * @param customerId the customerId to set
     */
    public void setCustomerId(int customerId) {
        this.customerId = customerId;
    }

    /*
     * (non-Javadoc)
     * 
     * @see java.lang.Object#toString()
     */

    @Override
    public String toString() {
        return "CompensationData [customerId=" + customerId + ", sagaId=" + sagaId + "]";
    }
}
