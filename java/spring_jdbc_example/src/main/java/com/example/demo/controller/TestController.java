/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0
as shown at http://oss.oracle.com/licenses/upl */

/*
 DESCRIPTION
 This code sample calls upon a rest endpoint to retrieve all students.
 It is part of the greater

 peter song    05/11/2022 - Creation
 */

package com.example.demo.controller;


import com.example.demo.Service.StudentService;
import com.example.demo.model.Student;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class TestController {
    @Autowired
    private StudentService studentService;
    @GetMapping(value = "/students")
    public List<Student> getAllStudents(){
        return studentService.findAll();
    }

}
