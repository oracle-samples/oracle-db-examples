package database;


import oracle.jdbc.pool.OracleDataSource;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.sql.Connection;
import java.sql.SQLException;


public class DatabaseConfig {

    final OracleDataSource ods;

    private static DatabaseConfig config;

    DatabaseConfig() {

        try {
            ods = new OracleDataSource();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public static synchronized DatabaseConfig get() {
        if (config == null ) {
            String URL = System.getProperty("ORACLE_URL");
            config = new DatabaseConfig()
                    .configure(URL);
        }
        return config;
    }

    private DatabaseConfig configure(String URL) {
        ods.setURL(URL);
        return this;
    }

    public Connection getConnection() throws SQLException {
        return ods.getConnection();
    }

}
