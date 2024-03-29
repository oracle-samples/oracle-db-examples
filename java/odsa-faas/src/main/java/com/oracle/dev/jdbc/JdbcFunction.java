/*
  Copyright (c) 2021, 2022, Oracle and/or its affiliates.

  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

package com.oracle.dev.jdbc;

import java.sql.SQLException;
import java.util.Map;
import java.util.Optional;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.HttpMethod;
import com.microsoft.azure.functions.HttpRequestMessage;
import com.microsoft.azure.functions.HttpResponseMessage;
import com.microsoft.azure.functions.HttpStatus;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;

/**
 * Azure JDBC Function with HTTP Trigger.
 */
public class JdbcFunction {
	/**
	 * This function listens at endpoint "/api/JdbcFunction". Two ways to invoke it
	 * using "curl" command in bash: 1. curl -d "HTTP Body" {your
	 * host}/api/JdbcFunction 2. curl "{your
	 * host}/api/JdbcFunction?name=<QUERY_NAME>&year=<QUERY_YEAR>"
	 */
	@FunctionName("JdbcFunction")
	public HttpResponseMessage run(@HttpTrigger(name = "req", methods = { HttpMethod.GET,
			HttpMethod.POST }, authLevel = AuthorizationLevel.ANONYMOUS) HttpRequestMessage<Optional<String>> request,
			final ExecutionContext context) {
		context.getLogger().info("JdbcFunction - Java HTTP trigger processed a request.");
		Map<String, String> httpRequestQueryParameters = request.getQueryParameters();
		Optional<String> httpRequestBody = request.getBody();
		String nameQueryString = httpRequestQueryParameters.get("name");
		String nameBody = httpRequestBody.orElse(nameQueryString);
		String yearQueryString = httpRequestQueryParameters.get("year");
		String yearBody = httpRequestBody.orElse(yearQueryString);
		String databaseQueryResults = null;
		if (nameBody == null || yearBody == null) {
			return request.createResponseBuilder(HttpStatus.BAD_REQUEST)
					.body("Please pass a name and a year on the query string or in the request body").build();
		} else {
			JdbcConnectionToOracleAtpOnOdsa jdbc = new JdbcConnectionToOracleAtpOnOdsa();
			try {
				databaseQueryResults = jdbc.runQuery(nameQueryString, Integer.parseInt(yearQueryString));
				context.getLogger().info("JDBC Query Results: " + databaseQueryResults);
			} catch (SQLException e) {
				e.printStackTrace();
			}
			return request.createResponseBuilder(HttpStatus.OK).body("The city is: " + databaseQueryResults).build();
		}
	}

}
