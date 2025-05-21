/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns.dto;

import java.util.List;

public record StartTransactionResponse(
        Long bookingId,
        String transactionId,
        Integer count,
        List<Long> seatIds
) {}
