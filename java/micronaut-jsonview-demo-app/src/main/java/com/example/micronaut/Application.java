/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

package com.example.micronaut;

import java.time.LocalTime;

import com.example.micronaut.entity.Course;
import com.example.micronaut.entity.Student;
import com.example.micronaut.entity.StudentCourse;
import com.example.micronaut.entity.Teacher;
import com.example.micronaut.repository.CourseRepository;
import com.example.micronaut.repository.StudentCourseRepository;
import com.example.micronaut.repository.StudentRepository;
import com.example.micronaut.repository.TeacherRepository;
import io.micronaut.context.event.StartupEvent;
import io.micronaut.runtime.Micronaut;
import io.micronaut.runtime.event.annotation.EventListener;
import jakarta.inject.Singleton;

@Singleton
public class Application {

    private final CourseRepository courseRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final StudentCourseRepository studentCourseRepository;

    public Application(
            CourseRepository courseRepository,
            StudentRepository studentRepository,
            TeacherRepository teacherRepository,
            StudentCourseRepository studentCourseRepository) {
        this.courseRepository = courseRepository;
        this.studentRepository = studentRepository;
        this.teacherRepository = teacherRepository;
        this.studentCourseRepository = studentCourseRepository;
    }

    public static void main(String[] args) {
        Micronaut.run(args);
    }

    @EventListener
    public void init(StartupEvent startupEvent) {
        // Clear the existing tables
        courseRepository.deleteAll();
        studentRepository.deleteAll();
        teacherRepository.deleteAll();
        studentCourseRepository.deleteAll();

        // Use relational operations to insert three new rows in the STUDENT table
        Student dennis = studentRepository.save(new Student("Denis", 8.5));
        Student jill = studentRepository.save(new Student("Jill", 7.2));
        Student devjani = studentRepository.save(new Student("Devjani", 9.1));

        // Use relational operations to insert three new rows in the TEACHER table
        Teacher teacherOlya = teacherRepository.save(new Teacher("Ms. Olya"));
        Teacher teacherGraeme = teacherRepository.save(new Teacher("Mr. Graeme"));
        Teacher teacherYevhen = teacherRepository.save(new Teacher("Prof. Yevhen"));

        // Use relational operations to insert three new rows in the COURSE table
        Course math = courseRepository.save(new Course("Math", "A101", LocalTime.of(10, 00), teacherGraeme));
        Course english = courseRepository.save(new Course("English", "A102", LocalTime.of(11, 00), teacherYevhen));
        Course history = courseRepository.save(new Course("History", "A103", LocalTime.of(12, 00), teacherOlya));

        // Use relational operations to inset six new rows into the STUDENT_COURSE table
        studentCourseRepository.save(new StudentCourse(dennis, math));
        studentCourseRepository.save(new StudentCourse(jill, math));
        studentCourseRepository.save(new StudentCourse(devjani, math));

        studentCourseRepository.save(new StudentCourse(dennis, history));
        studentCourseRepository.save(new StudentCourse(jill, english));
        studentCourseRepository.save(new StudentCourse(devjani, history));
    }
}
