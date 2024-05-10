/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.banka.util;

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

    public static final String BANKA = "banka";

    private static PoolDataSource configureDataSource() {
        final String OSAGA = "osaga.";

        String url = "jdbc:oracle:thin:@" + ConnectionPools.properties.getProperty(OSAGA + BANKA + ".tnsAlias");
        String maxpool = ConnectionPools.properties.getProperty(OSAGA + BANKA + ".maxpool");
        long keepalive = Long.parseLong(ConnectionPools.properties.getProperty("keepalive"));
        String walletPath = ConnectionPools.properties.getProperty(OSAGA + BANKA + ".walletPath");
        String tnsPath = ConnectionPools.properties.getProperty(OSAGA + BANKA + ".tnsPath");

        logger.debug("{}.url: {}", BANKA, url);
        logger.debug("{}.maxpool: {}", BANKA, maxpool);
        logger.debug("{}.walletPath: {}", BANKA, walletPath);
        logger.debug("{}.tnsPath: {}", BANKA, tnsPath);
        logger.debug("keepalive: {}", keepalive);

        PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();

        try {
            pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
            pds.setInitialPoolSize(Integer.parseInt(maxpool));
            pds.setMaxPoolSize(Integer.parseInt(maxpool));
            pds.setMinPoolSize(Integer.parseInt(maxpool));
            pds.setURL(url);
            pds.setConnectionPoolName(BANKA);
            pds.setConnectionProperty(OracleConnection.CONNECTION_PROPERTY_WALLET_LOCATION,
                    walletPath);
            pds.setConnectionProperty(OracleConnection.CONNECTION_PROPERTY_TNS_ADMIN, tnsPath);
        } catch (SQLException e) {
            logger.error("Unable to add connection for {} pool", BANKA);
            pds = null;
        }

        return pds;
    }

    private enum Accounts {
        INSTANCE();

        private final PoolDataSource ds;

        Accounts() {
            this.ds = configureDataSource();
        }

        public Connection getConnection() throws SQLException {
            return this.ds.getConnection();
        }
    }

    public static Connection getAccountsConnection() throws SQLException {
        return Accounts.INSTANCE.getConnection();
    }

    public static Properties getProperties() {
        return ConnectionPools.properties;
    }

}
