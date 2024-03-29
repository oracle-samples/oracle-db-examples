/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.bankb.listener;

import com.oracle.saga.bankb.util.ConnectionPools;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This is the main listener which is started upon application startup.
 */
@WebListener
public class AccountsServletContextListener implements ServletContextListener {
    private static final Logger logger = LoggerFactory
            .getLogger(AccountsServletContextListener.class);

    @Override
    public void contextInitialized(final ServletContextEvent servletContextEvent) {

        logger.info("Bank B deployment starting");

        try {
            ConnectionPools.getAccountsConnection();
        } catch (java.sql.SQLException e) {
            logger.error("Error creating pools");
        }
    }

    @Override
    public void contextDestroyed(final ServletContextEvent servletContextEvent) {
        logger.info("Bank B deployment shutting down!");
    }

}

