package com.oracle.saga.cloudbank.data;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * RefreshDTO class is used to map JSON request for refresh functionality.
 */
public class RefreshDTO {

    private String ucid;
    private String ossn;

    public String getUcid() {
        return ucid;
    }

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

    public void setUcid(String ucid) {
        this.ucid = ucid;
    }

    public String getOssn() {
        return ossn;
    }

    public void setOssn(String ossn) {
        this.ossn = ossn;
    }
}
