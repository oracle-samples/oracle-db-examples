/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.domain;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.math.BigDecimal;

@Entity(name = "ORDERS_ITEM")
@Table(name = "ORDERS_ITEM")
public class OrderItem {
    @NotNull
    @EmbeddedId
    private OrderItemId id;

    @Column(name = "PRICE", precision = 19, scale = 4)
    private BigDecimal price;

    @Size(max = 4)
    @Column(name = "STATUS", length = 4)
    private String status;

    @MapsId("orderId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumns({
            @JoinColumn(name = "COUNTRY", referencedColumnName = "COUNTRY", nullable = false),
            @JoinColumn(name = "CUSTID", referencedColumnName = "CUSTID", nullable = false),
            @JoinColumn(name = "ORDERID", referencedColumnName = "ORDERID", nullable = false)
    })
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Order orders;

    public OrderItemId getId() {
        return id;
    }

    public void setId(OrderItemId id) {
        this.id = id;
    }

    public com.foobar.appschema.domain.Order getOrders() {
        return orders;
    }

    public void setOrders(com.foobar.appschema.domain.Order orders) {
        this.orders = orders;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

}