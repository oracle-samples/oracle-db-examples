/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.dto;

import java.math.BigDecimal;

public record OrderItemResponse(
        Integer itemId,
        BigDecimal price,
        String status
) {
}