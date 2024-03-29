/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.cloudbank.listener;

import com.oracle.saga.cloudbank.util.ConnectionPools;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.sql.SQLException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This is the main listener which is started upon application startup.
 */
@WebListener
public class CloudBankServletContextListener implements ServletContextListener {
    private static final Logger logger = LoggerFactory
            .getLogger(CloudBankServletContextListener.class);

    @Override
    public void contextInitialized(final ServletContextEvent servletContextEvent) {

        logger.info("CloudBank deployment starting");

        try {
            ConnectionPools.getCloudBankConnection();
        } catch (SQLException e) {
            logger.error("Error creating pools");
        }
    }

    @Override
    public void contextDestroyed(final ServletContextEvent servletContextEvent) {
        logger.info("CloudBank deployment shutting down!");
    }

}

