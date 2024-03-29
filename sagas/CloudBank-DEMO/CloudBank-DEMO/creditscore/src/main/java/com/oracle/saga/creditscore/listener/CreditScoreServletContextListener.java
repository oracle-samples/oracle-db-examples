/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.creditscore.listener;

import com.oracle.saga.creditscore.util.ConnectionPools;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This is the main listener which is started upon application startup.
 */
@WebListener
public class CreditScoreServletContextListener implements ServletContextListener {
    private static final Logger logger = LoggerFactory
            .getLogger(CreditScoreServletContextListener.class);

    @Override
    public void contextInitialized(final ServletContextEvent servletContextEvent) {

        logger.info("CreditScore deployment starting");

        try {
            ConnectionPools.getCreditScoreConnection();
        } catch (java.sql.SQLException e) {
            logger.error("Error creating pools");
        }
    }

    @Override
    public void contextDestroyed(final ServletContextEvent servletContextEvent) {
        logger.info("CreditScore deployment shutting down!");
    }

}

