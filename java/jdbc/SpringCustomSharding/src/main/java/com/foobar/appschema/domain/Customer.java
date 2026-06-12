/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity(name = "CUSTOMER")
@Table(name = "CUSTOMER")
public class Customer {
    @Id
    @Column(name = "CUSTID", nullable = false, length = 60)
    private String custid;

    @Column(name = "FIRSTNAME", length = 60)
    private String firstname;

    @Column(name = "LASTNAME", length = 60)
    private String lastname;

    @Column(name = "CUSTPROFILE", length = 4000)
    private String custprofile;

    public String getCustid() {
        return custid;
    }

    public void setCustid(String custid) {
        this.custid = custid;
    }

    public String getFirstname() {
        return firstname;
    }

    public void setFirstname(String firstname) {
        this.firstname = firstname;
    }

    public String getLastname() {
        return lastname;
    }

    public void setLastname(String lastname) {
        this.lastname = lastname;
    }

    public String getCustprofile() {
        return custprofile;
    }

    public void setCustprofile(String custprofile) {
        this.custprofile = custprofile;
    }

    @Override
    public String toString() {
        return "Customer{" +
                "custid='" + custid + '\'' +
                ", firstname='" + firstname + '\'' +
                ", lastname='" + lastname + '\'' +
                ", custprofile='" + custprofile + '\'' +
                '}';
    }
}