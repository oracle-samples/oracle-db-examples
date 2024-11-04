/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.util;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import oracle.jdbc.OracleConnection;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class ConnectionPools {

    private static final Logger logger = LoggerFactory.getLogger(ConnectionPools.class);
    private static Properties properties = PropertiesHelper.loadProperties();

    private static PoolDataSource configureDataSource(Properties properties, String prefix) {
        final String OSAGA = "osaga.";

        logger.debug("parsing {}", prefix);

        String url = "jdbc:oracle:thin:@" + properties.getProperty(OSAGA + prefix + ".tnsAlias");
        String maxpool = properties.getProperty(OSAGA + prefix + ".maxpool");
        long keepalive = Long.parseLong(properties.getProperty("keepalive"));
        String walletPath = properties.getProperty(OSAGA + prefix + ".walletPath");
        String tnsPath = properties.getProperty(OSAGA + prefix + ".tnsPath");

        logger.debug("{}.url: {}", prefix, url);
        logger.debug("{}.maxpool: {}", prefix, maxpool);
        logger.debug("{}.walletPath: {}", prefix, walletPath);
        logger.debug("{}.tnsPath: {}", prefix, tnsPath);
        logger.debug("keepalive: {}", keepalive);

        PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();

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
            logger.error("Unable to add connection for {} pool", prefix, e);
            pds = null;
        }

        return pds;
    }

    private enum TravelAgency {
        INSTANCE();

        private final PoolDataSource ds;

        private TravelAgency() {
            this.ds = configureDataSource(ConnectionPools.properties, "travelagency");
        }

        public Connection getConnection() throws SQLException {
            return this.ds.getConnection();
        }
    }

    public static Connection getTravelAgencyConnection() throws SQLException {
        return TravelAgency.INSTANCE.getConnection();
    }

    public static Properties getProperties() {
        return ConnectionPools.properties;
    }

}
