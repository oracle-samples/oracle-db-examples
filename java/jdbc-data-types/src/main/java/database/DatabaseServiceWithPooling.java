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
DatabaseServiceWithPooling - Used to retrieve and setup connection to an Oracle Database
*/
package database;


import oracle.jdbc.OracleConnection;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.sql.SQLException;

public class DatabaseServiceWithPooling {
    private PoolDataSource pds;

    /**
     * Creates an instance of pool-enabled data source and configures connection properties
     * @throws SQLException
     */
    public DatabaseServiceWithPooling() throws SQLException {
        this.pds = PoolDataSourceFactory.getPoolDataSource();
        this.pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        this.pds.setURL(DatabaseConfig.getDbUrl());
        this.pds.setUser(DatabaseConfig.getDbUser());
        this.pds.setPassword(DatabaseConfig.getDbPassword());
    }

    /**
     * Gets a connection using the data source instance.
     * @return
     * @throws SQLException
     */
    public OracleConnection getDatabaseConnection() throws SQLException {
        return (OracleConnection) this.pds.getConnection();

    }
}