/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.cloudbank.data;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Objects;

/**
 * CreditScore class holds the request structure for CreditScore JSON request.
 */
public class CreditScore {

    private String creditOperationType;

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

    private String ossn;
    private String ucid;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof CreditScore)) return false;
        CreditScore that = (CreditScore) o;
        return Objects.equals(getCreditOperationType(), that.getCreditOperationType()) && Objects.equals(getOssn(), that.getOssn()) && Objects.equals(getUcid(), that.getUcid());
    }

    @Override
    public int hashCode() {
        return Objects.hash(getCreditOperationType(), getOssn(), getUcid());
    }



    public String getCreditOperationType() {
        return creditOperationType;
    }

    public void setCreditOperationType(String creditOperationType) {
        this.creditOperationType = creditOperationType;
    }

    public String getOssn() {
        return ossn;
    }

    public void setOssn(String ossn) {
        this.ossn = ossn;
    }

    public String getUcid() {
        return ucid;
    }

    public void setUcid(String ucid) {
        this.ucid = ucid;
    }



}
