/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

 package com.example.micronaut.dto;

import io.micronaut.serde.annotation.Serdeable;

import java.util.List;

@Serdeable
public record CreateStudentDto(
        String student,
        Double averageGrade,
        List<String> courses
) {}
