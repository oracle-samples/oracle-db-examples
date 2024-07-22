package com.oracle.jdbc.samples.statementinterceptordemo.services.impl;

import com.oracle.jdbc.samples.statementinterceptordemo.dao.EmployeeDAO;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

/**
 * Special service instance that use the interceptor
 */
@Service
@Qualifier("interceptedService")
public class EmployeeServiceInterceptorImpl extends EmployeeServiceImpl {

  public EmployeeServiceInterceptorImpl(
    @Qualifier("interceptorDAO") EmployeeDAO dao) {
    super(dao);
  }

}
