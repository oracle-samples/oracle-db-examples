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

package com.oracle.jdbc.samples.interceptor;

import oracle.jdbc.TraceEventListener;
import oracle.jdbc.spi.OracleResourceProvider;
import oracle.jdbc.spi.TraceEventListenerProvider;

import java.util.Collection;
import java.util.List;
import java.util.Map;

public class SQLStatementInterceptorProvider implements TraceEventListenerProvider {
  private static final InterceptorParameter parameter = new InterceptorParameter();
  private static final InterceptorJSONParameter jParameter = new InterceptorJSONParameter();
  private static final List<Parameter> parameters = List.of(parameter,
                                                            jParameter);

  @Override
  public TraceEventListener getTraceEventListener(Map<Parameter, CharSequence> parameterMap) {
    // we can load from file or JSON content.
    String rulesAsString = parameterMap.get(jParameter).toString();

    RuleConfiguration configuration;
    try {
      configuration = RuleConfiguration.fromJSON(rulesAsString);
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
