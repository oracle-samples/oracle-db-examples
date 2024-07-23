/*
 * Copyright (c) 2024, Oracle and/or its affiliates.
 *
 *   This software is dual-licensed to you under the Universal Permissive License
 *   (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
 *   2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
 *   either license.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *
 */

package com.oracle.jdbc.samples.statementinterceptordemo;

import com.oracle.jdbc.samples.interceptor.SQLStatementInterceptor;
import com.oracle.jdbc.samples.statementinterceptordemo.services.EmployeeService;
import com.oracle.jdbc.samples.statementinterceptordemo.utils.WebViolationHandler;
import lombok.extern.java.Log;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.util.logging.Logger;

@SpringBootApplication
@Log
public class StatementInterceptorDemoApplication {

  public static void main(String[] args) {
    SpringApplication.run(StatementInterceptorDemoApplication.class, args);
  }

  @Bean
  public CommandLineRunner commandLineRunner(final EmployeeService service) {
    return args -> {
      log.info("Initializing employees data ...");
      service.initialize();
      log.info("Employees data Initialized");

      // add our handler to violation logger
      Logger.getLogger(SQLStatementInterceptor.ACTION_LOGGER_NAME)
            .addHandler(new WebViolationHandler());


    };
  }

}
