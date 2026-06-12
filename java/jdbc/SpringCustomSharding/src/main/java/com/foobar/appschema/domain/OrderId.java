/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.hibernate.Hibernate;

import java.math.BigDecimal;
import java.util.Objects;

@Embeddable
public class OrderId implements java.io.Serializable {
    private static final long serialVersionUID = 7984358032443451555L;
    @Size(max = 40)
    @NotNull
    @Column(name = "COUNTRY", nullable = false, length = 40)
    private String country;

    @Size(max = 60)
    @NotNull
    @Column(name = "CUSTID", nullable = false, length = 60)
    private String custid;

    @NotNull
    @Column(name = "ORDERID", nullable = false)
    private BigDecimal orderid;

    public OrderId(String country, String custId, BigDecimal orderId) {
        this.country = country;
        this.custid = custId;
        this.orderid = orderId;
    }

    public OrderId() {}

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getCustid() {
        return custid;
    }

    public void setCustid(String custid) {
        this.custid = custid;
    }

    public BigDecimal getOrderid() {
        return orderid;
    }

    public void setOrderid(BigDecimal orderid) {
        this.orderid = orderid;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || Hibernate.getClass(this) != Hibernate.getClass(o)) return false;
        OrderId entity = (OrderId) o;
        return Objects.equals(this.country, entity.country) &&
                Objects.equals(this.orderid, entity.orderid) &&
                Objects.equals(this.custid, entity.custid);
    }

    @Override
    public int hashCode() {
        return Objects.hash(country, orderid, custid);
    }

}