/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0
as shown at http://oss.oracle.com/licenses/upl */

/*
 DESCRIPTION
 The code sample maps the students table from Autonomous Database
 to this students class, using JPA

 Peter Song    05/11/2022 - Creation
 */

package com.example.demo.model;


import javax.persistence.*;

@Entity
@Table(name = "Students")
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int ID;
    @Column(name = "first_name")
    String first_name;
    @Column(name = "last_name")
    String last_name;
    public Student(){

    }
    public Student(int ID, String first_name, String last_name) {
        this.ID = ID;
        this.first_name = first_name;
        this.last_name = last_name;
    }

    public int getID() {
        return ID;
    }

    public void setID(int ID) {
        this.ID = ID;
    }

    public String getFirst_name() {
        return first_name;
    }

    public void setFirst_name(String first_name) {
        this.first_name = first_name;
    }

    public String getLast_name() {
        return last_name;
    }

    public void setLast_name(String last_name) {
        this.last_name = last_name;
    }

    @Override
    public String toString() {
        return "Student{" +
                "ID=" + ID +
                ", first_name='" + first_name + '\'' +
                ", last_name='" + last_name + '\'' +
                '}';
    }
}
