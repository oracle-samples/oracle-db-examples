/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record OrderResponse(
        String country,
        String custId,
        BigDecimal orderId,
        LocalDateTime orderDate,
        BigDecimal sumTotal,
        String status,
        List<OrderItemResponse> items
) {
}