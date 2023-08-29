/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

package com.example.micronaut.entity.view;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.data.annotation.GeneratedValue;
import io.micronaut.data.annotation.Id;
import io.micronaut.data.annotation.JsonView;

import java.util.List;

@JsonView(value = "STUDENT_SCHEDULE")
public record StudentView(
        @Id
        @GeneratedValue(GeneratedValue.Type.IDENTITY)
        @Nullable
        Long studentId,
        String student,
        Double averageGrade,
        List<StudentScheduleView> schedule,
        @JsonProperty("_metadata")
        @Nullable Metadata metadata) {
        public StudentView(String student, Double averageGrade, List<StudentScheduleView> schedule) {
                this(null, student, averageGrade, schedule, null);
        }

        @Override
        public String toString() {
                return "Student{" +
                        "studentId=" + studentId +
                        ", student='" + student + '\'' +
                        ", averageGrade=" + averageGrade +
                        ", schedule=" + schedule +
                        '}';
        }
}