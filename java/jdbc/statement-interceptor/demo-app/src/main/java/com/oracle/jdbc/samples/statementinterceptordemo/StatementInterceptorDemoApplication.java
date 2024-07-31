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
import oracle.ucp.jdbc.PoolDataSourceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.util.logging.Logger;

@SpringBootApplication
@Log
public class StatementInterceptorDemoApplication {

  @Autowired @Qualifier("interceptedDataSource") DataSource DataSource1;
  @Autowired DataSource DataSource2;

  public static void main(String[] args) {
    SpringApplication.run(StatementInterceptorDemoApplication.class, args);
  }

  @Bean
  public CommandLineRunner commandLineRunner(final EmployeeService service) {
    return args -> {
      log.info("Initializing employees data ...");
      service.initialize();
      log.info("Employees data Initialized");

      log.info("starting connection pools ...");
      // That's ususally not needed but for the sake of the demo
      // we forcefully start the pool
      ((PoolDataSourceImpl)DataSource1).startPool();
      ((PoolDataSourceImpl)DataSource2).startPool();
      log.info("Pools started...");

      // add our handler to violation logger
      Logger.getLogger(SQLStatementInterceptor.ACTION_LOGGER_NAME)
            .addHandler(new WebViolationHandler());
    };
  }

}
