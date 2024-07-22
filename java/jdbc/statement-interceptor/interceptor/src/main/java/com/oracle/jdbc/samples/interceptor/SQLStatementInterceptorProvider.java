package com.oracle.jdbc.samples.interceptor;

import oracle.jdbc.TraceEventListener;
import oracle.jdbc.spi.TraceEventListenerProvider;

import java.util.Collection;
import java.util.List;
import java.util.Map;

public class SQLStatementInterceptorProvider implements TraceEventListenerProvider {
  private static final InterceptorParameter parameter = new InterceptorParameter();
  private static final List<InterceptorParameter> parameters = List.of(parameter);

  @Override
  public TraceEventListener getTraceEventListener(Map<Parameter, CharSequence> parameterMap) {
    String pathname = parameterMap.get(parameter).toString();
    RuleConfiguration configuration;
    try {
      configuration = RuleConfiguration.fromJSONFile(pathname);
    } catch (Exception e) {
      // what shall I do now ?
      return null;
    }
    return new SQLStatementInterceptor(configuration.getRules());
  }

  @Override
  public String getName() {
    return SQLStatementInterceptorProvider.class.getName();
  }

  @Override
  public Collection<? extends Parameter> getParameters() {
    return parameters;
  }
}
