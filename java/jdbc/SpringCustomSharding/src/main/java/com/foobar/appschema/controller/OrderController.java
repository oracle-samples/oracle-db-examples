/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.controller;

import com.foobar.ShardingController;
import com.foobar.appschema.dto.AppSchemaApiMapper;
import com.foobar.appschema.dto.OrderRequest;
import com.foobar.appschema.dto.OrderResponse;
import com.foobar.appschema.domain.Order;
import com.foobar.appschema.domain.OrderId;
import com.foobar.appschema.service.OrderService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping({"/orders"})
public class OrderController {

  private final OrderService orderService;

  @Autowired
  public OrderController(OrderService orderService) {
    this.orderService = orderService;
  }

  @GetMapping("/{country}/{custId}/{orderId}")
  public OrderResponse getOrder(
    @PathVariable("country") String country,
    @PathVariable("custId") String custId,
    @PathVariable("orderId") BigDecimal orderId) {
    OrderId id = new OrderId(country, custId, orderId);
    ShardingController.getShardingKeyContext().set(country);
    return AppSchemaApiMapper.toOrderResponse(orderService.getOrder(id));
  }

  @PostMapping
  public OrderResponse saveOrder(@Valid @RequestBody OrderRequest order) {
    ShardingController.getShardingKeyContext().set(order.country());
    Order saved = orderService.saveOrder(AppSchemaApiMapper.toOrder(order));
    return AppSchemaApiMapper.toOrderResponse(saved);
  }

}
