/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.dto;

public record CustomerResponse(
        String custId,
        String firstName,
        String lastName,
        String custProfile
) {
}