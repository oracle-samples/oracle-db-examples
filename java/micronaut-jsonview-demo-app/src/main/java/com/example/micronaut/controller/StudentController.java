/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

package com.example.micronaut.controller;

import java.util.Optional;

import com.example.micronaut.dto.CreateStudentDto;
import com.example.micronaut.entity.Student;
import com.example.micronaut.entity.StudentCourse;
import com.example.micronaut.entity.view.StudentView;
import com.example.micronaut.repository.CourseRepository;
import com.example.micronaut.repository.StudentCourseRepository;
import com.example.micronaut.repository.StudentRepository;
import com.example.micronaut.repository.view.StudentViewRepository;
import io.micronaut.core.annotation.NonNull;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Delete;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.Put;
import io.micronaut.http.annotation.Status;

@Controller("/students") // <1>
public final class StudentController {

    private final CourseRepository courseRepository;
    private final StudentRepository studentRepository;
    private final StudentCourseRepository studentCourseRepository;
    private final StudentViewRepository studentViewRepository;

    public StudentController(CourseRepository courseRepository, StudentRepository studentRepository, StudentCourseRepository studentCourseRepository, StudentViewRepository studentViewRepository) { // <2>
        this.courseRepository = courseRepository;
        this.studentRepository = studentRepository;
        this.studentCourseRepository = studentCourseRepository;
        this.studentViewRepository = studentViewRepository;
    }

    @Get("/") // <3>
    public Iterable<StudentView> findAll() {
        return studentViewRepository.findAll();
    }

    @Get("/student/{student}") // <4>
    public Optional<StudentView> findByStudent(@NonNull String student) {
        return studentViewRepository.findByStudent(student);
    }

    @Get("/{id}") // <5>
    public Optional<StudentView> findById(Long id) {
        return studentViewRepository.findById(id);
    }

    @Put("/{id}/average_grade/{averageGrade}") // <6>
    public Optional<StudentView> updateAverageGrade(Long id, @NonNull Double averageGrade) {
        //Use a duality view operation to update a student's average grade
        return studentViewRepository.findById(id).flatMap(studentView -> {
            studentViewRepository.updateAverageGrade(id, averageGrade);
            return studentViewRepository.findById(id);
        });
    }

    @Put("/{id}/student/{student}") // <7>
    public Optional<StudentView> updateStudent(Long id, @NonNull String student) {
        //Use a duality view operation to update a student's name
        return studentViewRepository.findById(id).flatMap(studentView -> {
            studentViewRepository.updateStudentByStudentId(id, student);
            return studentViewRepository.findById(id);
        });
    }

    @Post("/") // <8>
    @Status(HttpStatus.CREATED) 
    public Optional<StudentView> create(@NonNull @Body CreateStudentDto createDto) {
      // Use a relational operation to insert a new row in the STUDENT table
      Student student = studentRepository.save(new Student(createDto.student(), createDto.averageGrade()));
      // For each of the courses in createDto parameter, insert a row in the STUDENT_COURSE table
      courseRepository.findByNameIn(createDto.courses()).stream()
          .forEach(course -> studentCourseRepository.save(new StudentCourse(student, course)));
      return studentViewRepository.findByStudent(student.name());
    }

    @Delete("/{id}") // <9>
    @Status(HttpStatus.NO_CONTENT)
    void delete(Long id) {
        //Use a duality view operation to delete a student
        studentViewRepository.deleteById(id);
    }

    @Get("/max_average_grade") // <10>
    Optional<Double> findMaxAverageGrade() {
        return studentViewRepository.findMaxAverageGrade();
    }
}