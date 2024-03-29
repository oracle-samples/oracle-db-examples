package com.oracle.saga.creditscore.data;

/**
 * CreditScoreDTO is a class used to store saga compensation objects in cache.
 */
public class CreditScoreDTO {


    public String getOssn() {
        return ossn;
    }

    public void setOssn(String ossn) {
        this.ossn = ossn;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    private String ossn;
    private String fullName;



}
