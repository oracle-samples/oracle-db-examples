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
import io.micronaut.data.annotation.MappedProperty;
import io.micronaut.data.annotation.Relation;

@MappedEntity("STUDENT_COURSE")
public record StudentCourse(
    @Id
    @GeneratedValue(GeneratedValue.Type.AUTO)
    @Nullable
    Long id,
    @Relation(Relation.Kind.MANY_TO_ONE)
    Student student,
    @Relation(Relation.Kind.MANY_TO_ONE)
    @MappedProperty("COURSE_ID")
    Course course) {

    public StudentCourse(Student student, Course course) {
        this(null, student, course);
    }
}