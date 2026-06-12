/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.domain;

import jakarta.persistence.Column;
import jakarta.persistence.AttributeOverride;
import jakarta.persistence.AttributeOverrides;
import jakarta.persistence.Embedded;
import jakarta.persistence.Embeddable;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.Objects;

@Embeddable
public class OrderItemId implements java.io.Serializable {
    private static final long serialVersionUID = 5055718089549847752L;

    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name = "country", column = @Column(name = "COUNTRY", nullable = false, length = 40)),
            @AttributeOverride(name = "custid", column = @Column(name = "CUSTID", nullable = false, length = 60)),
            @AttributeOverride(name = "orderid", column = @Column(name = "ORDERID", nullable = false))
    })
    private OrderId orderId;

    @NotNull
    @Column(name = "ITEMID", nullable = false)
    private BigDecimal itemId;

    public OrderItemId(String country, String custId, BigDecimal orderId, BigDecimal itemId) {
        this.orderId = new OrderId(country, custId, orderId);
        this.itemId = itemId;
    }

    public OrderItemId() {}

    public OrderId getOrderId() {
        return orderId;
    }

    public void setOrderId(OrderId orderId) {
        this.orderId = orderId;
    }

    public String getCountry() {
        return orderId != null ? orderId.getCountry() : null;
    }

    public void setCountry(String country) {
        if (orderId == null) {
            orderId = new OrderId();
        }
        orderId.setCountry(country);
    }

    public String getCustid() {
        return orderId != null ? orderId.getCustid() : null;
    }

    public void setCustid(String custid) {
        if (orderId == null) {
            orderId = new OrderId();
        }
        orderId.setCustid(custid);
    }

    public BigDecimal getOrderid() {
        return orderId != null ? orderId.getOrderid() : null;
    }

    public void setOrderid(BigDecimal orderid) {
        if (orderId == null) {
            orderId = new OrderId();
        }
        orderId.setOrderid(orderid);
    }

    public BigDecimal getItemid() {
        return itemId;
    }

    public void setItemid(BigDecimal itemid) {
        this.itemId = itemid;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        OrderItemId that = (OrderItemId) o;
        return Objects.equals(orderId, that.orderId) && Objects.equals(itemId, that.itemId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(orderId, itemId);
    }
}