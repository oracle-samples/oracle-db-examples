/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0
as shown at http://oss.oracle.com/licenses/upl */

/*
 DESCRIPTION
 The code sample maps uses the jpaRepository to return
 all students

 Peter Song    05/11/2022 - Creation
 */

package com.example.demo.Service;


import com.example.demo.model.Student;
import com.example.demo.repository.StudentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class StudentService {
    @Autowired
    private StudentRepository studentRepository;
    public List<Student> findAll(){
        List<Student> students = studentRepository.findAll();
        return students;
    }
}
