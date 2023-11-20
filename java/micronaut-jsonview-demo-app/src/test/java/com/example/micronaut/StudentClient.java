package com.example.micronaut;

import com.example.micronaut.dto.CreateStudentDto;
import com.example.micronaut.entity.view.StudentView;
import io.micronaut.core.annotation.NonNull;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Delete;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.Put;
import io.micronaut.http.annotation.Status;
import io.micronaut.http.client.annotation.Client;
import jakarta.validation.Valid;

import java.util.List;
import java.util.Optional;

@SuppressWarnings("unused")
@Client("/students")
interface StudentClient {

    @Get
    List<StudentView> findAll();

    @Get("/student/{student}")
    Optional<StudentView> findByStudent(String student);

    @Get("/{id}")
    Optional<StudentView> findById(Long id);

    @Put("/{id}/average_grade/{averageGrade}")
    Optional<StudentView> updateAverageGrade(Long id, @NonNull Double averageGrade);

    @Put("/{id}/student/{student}")
    Optional<StudentView> updateStudent(Long id, @NonNull String student);

    @Post
    Optional<StudentView> save(@Valid @Body CreateStudentDto createStudentDto);

    @Delete("/{id}")
    @Status(HttpStatus.NO_CONTENT)
    void delete(Long id);

    @Get("/max_average_grade")
    Optional<Double> findMaxAverageGrade();
}
