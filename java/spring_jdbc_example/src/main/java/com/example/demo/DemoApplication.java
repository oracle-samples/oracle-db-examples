/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0
as shown at http://oss.oracle.com/licenses/upl */

/*
 DESCRIPTION
 This is the main class that runs the springboot application

 Peter Song    05/11/2022 - Creation
 */

package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}

}
