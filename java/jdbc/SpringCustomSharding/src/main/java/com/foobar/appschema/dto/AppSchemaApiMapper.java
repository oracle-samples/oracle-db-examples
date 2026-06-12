/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.dto;

import com.foobar.appschema.domain.Customer;
import com.foobar.appschema.domain.Order;
import com.foobar.appschema.domain.OrderId;
import com.foobar.appschema.domain.OrderItem;
import com.foobar.appschema.domain.OrderItemId;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;

public final class AppSchemaApiMapper {

    private AppSchemaApiMapper() {
    }

    public static Customer toCustomer(CustomerRequest request) {
        Customer customer = new Customer();
        customer.setCustid(request.custId());
        customer.setFirstname(request.firstName());
        customer.setLastname(request.lastName());
        customer.setCustprofile(request.custProfile());
        return customer;
    }

    public static CustomerResponse toCustomerResponse(Customer customer) {
        return new CustomerResponse(
                customer.getCustid(),
                customer.getFirstname(),
                customer.getLastname(),
                customer.getCustprofile()
        );
    }

    public static Order toOrder(OrderRequest request) {
        Order order = new Order();
        order.setId(new OrderId(request.country(), request.custId(), request.orderId()));
        order.setOrderdate(request.orderDate());
        order.setSumtotal(request.sumTotal());
        order.setStatus(request.status());

        LinkedHashSet<OrderItem> items = new LinkedHashSet<>();
        for (OrderItemRequest itemRequest : request.items()) {
            OrderItem item = new OrderItem();
            item.setId(new OrderItemId(request.country(), request.custId(), request.orderId(), BigDecimal.valueOf(itemRequest.itemId())));
            item.setPrice(itemRequest.price());
            item.setStatus(itemRequest.status());
            item.setOrders(order);
            items.add(item);
        }
        order.setOrderitems(items);
        return order;
    }

    public static OrderResponse toOrderResponse(Order order) {
        List<OrderItemResponse> items = new ArrayList<>();
        if (order.getOrderitems() != null) {
            order.getOrderitems().stream()
                    .sorted(Comparator.comparing(item -> item.getId().getItemid()))
                    .forEach(item -> items.add(toOrderItemResponse(item)));
        }
        return new OrderResponse(
                order.getId().getCountry(),
                order.getId().getCustid(),
                order.getId().getOrderid(),
                order.getOrderdate(),
                order.getSumtotal(),
                order.getStatus(),
                items
        );
    }

    private static OrderItemResponse toOrderItemResponse(OrderItem item) {
        return new OrderItemResponse(
                item.getId().getItemid().intValue(),
                item.getPrice(),
                item.getStatus()
        );
    }
}