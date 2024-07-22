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
