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

package com.oracle.jdbc.dev.rsi;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

/**
 * <p>
 * Configuration for connecting code samples to an Oracle Database instance.
 * </p>
 */
public class DatabaseConfig {

	private static final Properties CONFIG = new Properties();

	static {
		try {
			var fileStream = Files.newInputStream(
					Path.of("C:\\java-projects\\rsi-introduction\\src\\main\\resources\\config.properties"));
			CONFIG.load(fileStream);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/** Host name where an Oracle Database instance is running */
	static final String HOST = CONFIG.getProperty("HOST");

	/** Port number where an Oracle Database instance is listening */
	static final int PORT = Integer.parseInt(CONFIG.getProperty("PORT"));

	/** Service name of an Oracle Database */
	static final String SERVICE_NAME = CONFIG.getProperty("DATABASE");

	/** User name that connects to an Oracle Database */
	static final String USER = CONFIG.getProperty("USER");

	/** Password of the user that connects to an Oracle Database */
	static final String PASSWORD = CONFIG.getProperty("PASSWORD");

	/** Database schema */
	static final String SCHEMA = CONFIG.getProperty("SCHEMA");

	/** The file system path of a wallet directory */
	static final String WALLET_LOCATION = CONFIG.getProperty("WALLET_LOCATION");

	/** Colon for URL composition */
	static final String COLON = ":";

	/** JDBC EZConnect URL format */
	static final String JDBC_EZ_CONNECT_FORMAT = "jdbc:oracle:thin:@";

	/** Helper method to get the JDBC URL */
	static final String getJdbcConnectionUrl() {
		StringBuilder url = new StringBuilder(JDBC_EZ_CONNECT_FORMAT).append(DatabaseConfig.HOST).append(COLON)
				.append(PORT).append(COLON).append(SERVICE_NAME);
		return url.toString();
	}

}
