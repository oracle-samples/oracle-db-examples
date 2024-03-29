/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.creditscore.util;

import oracle.jdbc.OracleConnection;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * ConnectionPools is a class which helps configure data source using the application.properties file.
 */
public class ConnectionPools {

    private static final Logger logger = LoggerFactory.getLogger(ConnectionPools.class);
    private static final Properties properties = PropertiesHelper.loadProperties();

    private static PoolDataSource configureDataSource(String prefix) {
        final var OSAGA = "osaga.";

        String url = "jdbc:oracle:thin:@" + ConnectionPools.properties.getProperty(OSAGA + prefix + ".tnsAlias");
        String maxpool = ConnectionPools.properties.getProperty(OSAGA + prefix + ".maxpool");
        var keepalive = Long.parseLong(ConnectionPools.properties.getProperty("keepalive"));
        String walletPath = ConnectionPools.properties.getProperty(OSAGA + prefix + ".walletPath");
        String tnsPath = ConnectionPools.properties.getProperty(OSAGA + prefix + ".tnsPath");

        logger.debug("{}.url: {}", prefix, url);
        logger.debug("{}.maxpool: {}", prefix, maxpool);
        logger.debug("{}.walletPath: {}", prefix, walletPath);
        logger.debug("{}.tnsPath: {}", prefix, tnsPath);
        logger.debug("keepalive: {}", keepalive);

        var pds = PoolDataSourceFactory.getPoolDataSource();

        try {
            pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
            pds.setInitialPoolSize(Integer.parseInt(maxpool));
            pds.setMaxPoolSize(Integer.parseInt(maxpool));
            pds.setMinPoolSize(Integer.parseInt(maxpool));
            pds.setURL(url);
            pds.setConnectionPoolName(prefix);
            pds.setConnectionProperty(OracleConnection.CONNECTION_PROPERTY_WALLET_LOCATION,
                    walletPath);
            pds.setConnectionProperty(OracleConnection.CONNECTION_PROPERTY_TNS_ADMIN, tnsPath);
        } catch (SQLException e) {
            logger.error("Unable to add connection for {} pool", prefix);
            pds = null;
        }

        return pds;
    }

    private enum CreditScore {
        INSTANCE();

        private final PoolDataSource ds;

        CreditScore() {
            this.ds = configureDataSource("creditscore");
        }

        public Connection getConnection() throws SQLException {
            return this.ds.getConnection();
        }
    }

    public static Connection getCreditScoreConnection() throws SQLException {
        return CreditScore.INSTANCE.getConnection();
    }

    public static Properties getProperties() {
        return ConnectionPools.properties;
    }

}
