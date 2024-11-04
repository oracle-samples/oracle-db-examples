package database;


import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.sql.Connection;
import java.sql.SQLException;


public class DatabasePoolConfig {

    final String factoryClassName = "oracle.jdbc.pool.OracleDataSource";
    final String poolDataSourceName = "JDBC_UCP_POOL";
    final PoolDataSource pool;

    private static DatabasePoolConfig config;

    DatabasePoolConfig() {
        pool = PoolDataSourceFactory.getPoolDataSource();
    }

    public static synchronized DatabasePoolConfig get() {
        if (config == null ) {
            String URL = System.getProperty("ORACLE_URL");
            config = new DatabasePoolConfig()
                    .configure(URL);
        }
        return config;
    }

    private DatabasePoolConfig configure(String URL) {
        System.out.println("Configuring with " + URL);
        try {
            pool.setURL(URL);
            pool.setConnectionPoolName(poolDataSourceName);
            pool.setConnectionFactoryClassName(factoryClassName);
            pool.setInitialPoolSize(100);
        } catch (SQLException e) {
            System.out.println("Error setting up oracle.jdbc.pool.OracleDataSource");
            throw new RuntimeException(e);
        }
        return this;
    }

    public Connection getConnection() throws SQLException {
        return pool.getConnection();
    }

}
