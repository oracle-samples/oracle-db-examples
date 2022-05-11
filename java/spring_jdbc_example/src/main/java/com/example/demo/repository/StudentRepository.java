/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0
as shown at http://oss.oracle.com/licenses/upl */

/*
 DESCRIPTION
 The code sample extends the JpaRepository
 to take advantage of built-in queries provided
 by JPA

 Peter Song    05/11/2022 - Creation
 */

package com.example.demo.repository;


import com.example.demo.model.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.transaction.Transactional;

@Repository
@Transactional
@EnableTransactionManagement
public interface StudentRepository extends JpaRepository<Student, Integer> {


}
