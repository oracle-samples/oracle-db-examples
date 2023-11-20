/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

package com.example.micronaut;

import com.example.micronaut.dto.CreateStudentDto;
import com.example.micronaut.entity.view.StudentView;
import com.example.micronaut.repository.view.StudentViewRepository;
import io.micronaut.runtime.server.EmbeddedServer;
import io.micronaut.test.extensions.junit5.annotation.MicronautTest;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@MicronautTest
class ApplicationTest {
    @Test
    void testStartup(EmbeddedServer embeddedServer, StudentViewRepository viewRepository) {
        assertTrue(embeddedServer.isRunning());
        assertTrue(viewRepository.count() > 0);
        assertFalse(viewRepository.findAll().isEmpty());
    }

    @Test
    void testCrud(StudentClient studentClient) {
        // initially created
        List<StudentView> studentViews = studentClient.findAll();
        assertFalse(studentViews.isEmpty());
        assertEquals(3, studentViews.size());

        // Create new
        CreateStudentDto createStudentDto = new CreateStudentDto("Aniko", 8.5, List.of("Math", "English"));
        Optional<StudentView> optStudentView = studentClient.save(createStudentDto);
        assertTrue(optStudentView.isPresent());
        StudentView studentView = optStudentView.get();
        assertEquals("Aniko", studentView.student());
        // Student has two courses
        assertEquals(2, studentView.schedule().size());

        // Find by name
        optStudentView = studentClient.findByStudent("Aniko");
        assertTrue(optStudentView.isPresent());
        studentView = optStudentView.get();
        assertEquals(8.5, studentView.averageGrade());

        studentViews = studentClient.findAll();
        // There is one more now
        assertEquals(4, studentViews.size());
    }
}
