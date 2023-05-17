/* Copyright (c) 2021, 2022, Oracle and/or its affiliates.
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

DESCRIPTION
DatabaseService - Used to retrieve setup connection productInformation to an Oracle Database and provide
*/
package database;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.datasource.impl.OracleDataSource;
import java.sql.SQLException;
import java.util.Properties;

public class DatabaseService {

    private final OracleDataSource ods;

    public DatabaseService() throws SQLException {
        // declare const variables
        final String DB_USER = DatabaseConfig.getDbUser();
        final String DB_URL = DatabaseConfig.getDbUrl();
        final String DB_PASSWORD = DatabaseConfig.getDbPassword();
        final boolean DB_FAN_ENABLED = false;

        // set properties with connection productInformation
        Properties info = new Properties();
        info.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, DB_USER);
        info.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, DB_PASSWORD);
        info.put(OracleConnection.CONNECTION_PROPERTY_FAN_ENABLED, DB_FAN_ENABLED);

        // instantiate OracleDataSource and set connection productInformation
        this.ods = new OracleDataSource();
        this.ods.setURL(DB_URL);
        this.ods.setConnectionProperties(info);
    }

    /**
     * getDatabaseConnection provides the connection to the database. We recommend using some connection
     * pooling to reuse connections, which is not demonstrated in this example.
     * @return OracleConnection
     * @throws SQLException
     */
    public OracleConnection getDatabaseConnection() throws SQLException {
        return (OracleConnection) this.ods.getConnection();
    }
}
