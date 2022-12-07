/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.

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
