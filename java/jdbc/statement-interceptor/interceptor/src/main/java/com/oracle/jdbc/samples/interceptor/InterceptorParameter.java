package com.oracle.jdbc.samples.interceptor;

import oracle.jdbc.spi.OracleResourceProvider;

class InterceptorParameter implements OracleResourceProvider.Parameter {
  public static final String NAME = "configuration";

  @Override
  public String name() {
    return NAME;
  }

  @Override
  public String description() {
    return "pathname of JSON configuration file";
  }

  @Override
  public boolean isSensitive() {
    return true;
  }
}
