/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

 package com.example.micronaut.entity;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.GeneratedValue;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.MappedEntity;
import io.micronaut.data.annotation.Relation;
import io.micronaut.data.annotation.sql.JoinTable;

import java.util.Collections;
import java.util.List;

@MappedEntity
public record Student(
    @Id
    @GeneratedValue(GeneratedValue.Type.AUTO)
    @Nullable
    Long id,
    String name,
    Double averageGrade,
    @JoinTable(name = "STUDENT_COURSE")
    @Relation(Relation.Kind.MANY_TO_MANY)
    List<Course> courses) {

    public Student(String name, Double averageGrade) {
        this(null, name, averageGrade, Collections.emptyList());
    }
}
