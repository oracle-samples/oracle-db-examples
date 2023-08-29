/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

 package com.example.micronaut.entity.view;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record Metadata(
        String etag,
        String asof) {
}
