/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.bankb.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;
import java.util.Properties;

/**
 * PropertiesHelper is used to fetch values from the application.properties file
 */
public class PropertiesHelper {
    private static final Logger logger = LoggerFactory.getLogger(PropertiesHelper.class);

    private PropertiesHelper() {
    }

    public static Properties loadProperties() {
        Properties p = new Properties();
        InputStream in = null;
        try {
            ClassLoader loader = PropertiesHelper.class.getClassLoader();
           if(loader!=null)
           {
            in = loader.getResourceAsStream("application.properties");
           }
            if(in!=null)
                p.load(in);
        } catch (java.io.IOException e) {
            logger.error("Could NOT load application.properties file");
        }finally{
            try {
                if (in != null) {
                    in.close();
                }
            }catch(java.io.IOException e){
                logger.error("Could NOT load application.properties file");
            }
        }
        return p;
    }
}