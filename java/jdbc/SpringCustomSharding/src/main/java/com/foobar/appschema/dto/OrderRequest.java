/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record OrderRequest(
        @NotBlank @Size(max = 40) String country,
        @NotBlank @Size(max = 60) String custId,
        @NotNull BigDecimal orderId,
        @NotNull LocalDateTime orderDate,
        @NotNull @DecimalMin("0.00") BigDecimal sumTotal,
        @NotBlank @Size(max = 4) String status,
        @NotEmpty List<@Valid OrderItemRequest> items
) {
}