package com.oracle.jdbc.samples.statementinterceptordemo.dao.impl;

import lombok.extern.java.Log;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
@Qualifier("interceptorDAO")
@Log
public class EmployeeDAOInterceptorImpl extends EmployeeDAOImpl {

  public EmployeeDAOInterceptorImpl(
    @Qualifier("interceptedJdbcTemplate") JdbcTemplate jdbcTemplate) {
    super(jdbcTemplate);
  }

}
