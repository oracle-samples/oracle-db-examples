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

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity(name = "ORDER")
@Table(name = "ORDERS")
public class Order {
    @NotNull
    @EmbeddedId
    private OrderId id;

    @NotNull
    @Column(name = "ORDERDATE", nullable = false)
    private LocalDateTime orderdate;

    @Column(name = "SUMTOTAL", precision = 19, scale = 4)
    private BigDecimal sumtotal;

    @Size(max = 4)
    @Column(name = "STATUS", length = 4)
    private String status;

    @OneToMany(mappedBy = "orders", fetch = FetchType.LAZY, cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<OrderItem> orderItems = new LinkedHashSet<>();

    public Order() {}

    public OrderId getId() {
        return id;
    }

    public void setId(OrderId id) {
        this.id = id;
    }

    public LocalDateTime getOrderdate() {
        return orderdate;
    }

    public void setOrderdate(LocalDateTime orderdate) {
        this.orderdate = orderdate;
    }

    public BigDecimal getSumtotal() {
        return sumtotal;
    }

    public void setSumtotal(BigDecimal sumtotal) {
        this.sumtotal = sumtotal;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Set<OrderItem> getOrderitems() {
        return orderItems;
    }

    public void setOrderitems(Set<OrderItem> orderItems) {
        this.orderItems = orderItems;
    }

}