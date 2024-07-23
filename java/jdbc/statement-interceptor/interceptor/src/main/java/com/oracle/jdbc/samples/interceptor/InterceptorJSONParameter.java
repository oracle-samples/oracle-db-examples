package com.oracle.jdbc.samples.interceptor;

import oracle.jdbc.spi.OracleResourceProvider;

public class InterceptorJSONParameter implements OracleResourceProvider.Parameter {
  public static final String NAME = "JSONConfiguration";

  @Override
  public String name() {
    return NAME;
  }

  @Override
  public String description() {
    return "Rules JSON configuration";
  }

  @Override
  public boolean isSensitive() {
    return true;
  }
}
