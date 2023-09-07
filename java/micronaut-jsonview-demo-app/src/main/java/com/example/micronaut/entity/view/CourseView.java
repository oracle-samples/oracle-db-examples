/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

 package com.example.micronaut.entity.view;

import com.example.micronaut.entity.Course;
import io.micronaut.serde.annotation.Serdeable;

import java.time.LocalTime;

@Serdeable
public record CourseView(
        Long courseId,
        String name,
        TeacherView teacher,
        String room,
        LocalTime time) {


    public CourseView(Course course) {
        this(
                course.id(),
                course.name(),
                new TeacherView(
                        course.teacher().id(),
                        course.teacher().name()
                ),
                course.room(),
                course.time()
        );
    }

    @Override
    public String toString() {
        return "Course{" +
                "courseId=" + courseId +
                ", teacher=" + teacher +
                ", room='" + room + '\'' +
                ", time=" + time +
                '}';
    }
}