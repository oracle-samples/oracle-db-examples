/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.car;

import java.io.InputStream;
import java.io.Reader;
import java.io.StringReader;
import java.net.URI;
import java.sql.Connection;
import java.util.Properties;
import java.util.Scanner;

import org.eclipse.microprofile.lra.annotation.Compensate;
import org.eclipse.microprofile.lra.annotation.Complete;
import org.ehcache.Cache;
import org.ehcache.CacheManager;
import org.ehcache.config.builders.CacheConfigurationBuilder;
import org.ehcache.config.builders.CacheManagerBuilder;
import org.ehcache.config.builders.ResourcePoolsBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.oracle.saga.travelagency.util.PropertiesHelper;

import oracle.AQ.AQOracleDebug;
import oracle.saga.SagaException;
import oracle.saga.SagaMessageContext;
import oracle.saga.SagaParticipant;
import oracle.saga.annotation.BeforeCompensate;
import oracle.saga.annotation.BeforeComplete;
import oracle.saga.annotation.InviteToJoin;
import oracle.saga.annotation.Participant;
import oracle.saga.annotation.Request;
import oracle.sql.json.OracleJsonException;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonParser;

@Participant(name = "Car")
public class Car extends SagaParticipant {

    private static final String REG_EXP_REMOVE_QUOTES = "(^\")|(\"$)";
    private static final String FAILURE = "{\"result\":\"failure\"}";

    private static final Logger logger = LoggerFactory.getLogger(Car.class);

    CacheManager cacheManager;

    public Car(CacheManager cacheManager) throws SagaException {
        super(true);

        this.cacheManager = cacheManager;
    }

    @Complete
    public void onPostCommit(URI sagaId) throws SagaException {
        SagaMessageContext context = this.getSagaMessageContext(sagaId.toString());
        logger.debug("After Commit(URI) from {} for {}", context.getSender(), sagaId);
    }

    public void onPostCommit(SagaMessageContext info) {
        logger.debug("After Commit(SMC) from {} for {}", info.getSender(), info.getSagaId());
    }

    @Compensate
    public void onPostRollback(SagaMessageContext info) {
        logger.debug("After Rollback(SMC) from {} for {}", info.getSender(), info.getSagaId());
        Connection connection = null;

        long start = System.currentTimeMillis();
        long end = 0;

        try {
            connection = info.getConnection();
        } catch (SagaException e) {
            logger.error("Unable to get database connection for car rental", e);
        }

        try {
            Cache<String, CompensationData> cachedCompensationInfo = cacheManager
                    .getCache("carCompensationData", String.class, CompensationData.class);
            CompensationData carCompensationInfo = cachedCompensationInfo.get(info.getSagaId());

            CarService car = new CarService(connection, this.cacheManager);
            int customerId = carCompensationInfo.getCustomerId();

            if (!car.rollbackInvalidCarBooking(customerId)) {
                logger.error("Unable to remove customer {} from car rental list.", customerId);
            } else {
                logger.debug("Customer {} was successfully removed from car rental list.",
                        customerId);
            }

        } catch (Exception e) {
            logger.error("Car Response", e);
        }

        end = System.currentTimeMillis();
        logger.debug("Status of compensation, rt: {}", end - start);

    }

    public void onPreCommit(SagaMessageContext info) {
        logger.debug("Before Commit(SMC) from {} for {}", info.getSender(), info.getSagaId());
    }

    @BeforeComplete
    public void onPreCommit(URI sagaId, URI parentId) throws SagaException {
        SagaMessageContext context = this.getSagaMessageContext(sagaId.toString());
        logger.debug("Before Commit(URI, URI) from {} for {} with parent {}", context.getSender(),
                sagaId, parentId);
    }

    @BeforeCompensate
    public void onPreRollback(SagaMessageContext info) {
        logger.debug("Before Rollback(SMC) from {} for {}", info.getSender(), info.getSagaId());
    }

    @InviteToJoin
    public boolean onInviteToJoin(SagaMessageContext info) {
        logger.debug("Joining saga: {}", info.getSagaId());
        return true;
    }

    @Request(sender = "TravelAgency")
    public String onRequest(SagaMessageContext info) {
        logger.debug("Handling {} from {}", info.getSagaId(), info.getSender());
        logger.debug("Payload: {}", info.getPayload());

        Connection connection = null;

        long start = System.currentTimeMillis();
        long end = 0;

        String status = FAILURE;

        try {
            connection = info.getConnection();
        } catch (SagaException e) {
            logger.error("Unable to get database connection for flight", e);
        }

        CarService car;
        try {
            car = new CarService(connection, this.cacheManager);

            String carAction = parseCarAction(info.getPayload());

            switch (carAction) {
            case "booking":
                if (car.bookCar(info.getPayload(), info.getSagaId())) {
                    status = "{\"result\":\"success\"}";
                }
                break;
            case "update":
                break;
            default:
                logger.error("Invalid car action specified: {}", carAction);
            }
        } catch (Exception e) {
            logger.error("Unable to create car reservation", e);
        }
        end = System.currentTimeMillis();
        logger.debug("Status of {} returned, rt: {}", status, end - start);

        return status;
    }

    /**
     * Parse the payload for which action to take.
     * 
     * @param payload The payload to parse.
     * @return the action to take or empty string if no action is found.
     */
    private String parseCarAction(String payload) {
        Reader inputReader = new StringReader(payload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        String carAction = "";

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject currentJsonObj = parser.getObject();
            carAction = currentJsonObj.get("action").toString()
                    .replaceAll(REG_EXP_REMOVE_QUOTES, "").toLowerCase();
        } catch (OracleJsonException ex) {
            logger.error("Unable to parse payload", ex);
        }
        return carAction;
    }

    public static void main(String[] args) {
        AQOracleDebug.setTraceLevel(1);

        Properties p = new Properties();
        try (InputStream in = PropertiesHelper.class.getClassLoader()
                .getResourceAsStream("application.properties")) {
            p.load(in);
        } catch (Exception e) {
            logger.error("Could NOT load application.properties file", e);
        }

        int cacheSize = Integer.parseInt(p.getProperty("cacheSize", "100000"));
        logger.debug("cache size: {}", cacheSize);

        CacheManager cacheManager;
        cacheManager = CacheManagerBuilder.newCacheManagerBuilder().build(true);
        cacheManager.createCache("carCompensationData",
                CacheConfigurationBuilder.newCacheConfigurationBuilder(String.class,
                        CompensationData.class, ResourcePoolsBuilder.heap(cacheSize)));

        try {
            logger.info("Starting Car");
            Car car = new Car(cacheManager);
            car.startWorkers();

            try (Scanner kbReader = new Scanner(System.in)) {
                String input = "";
                do {
                    System.out.println("Please Q or q to end application.");
                    input = kbReader.nextLine();
                } while (!input.equalsIgnoreCase("Q"));
            }

            logger.info("Car shutting down.");
            car.close();

        } catch (SagaException ex) {
            logger.error("SagaException trying to instantiate SagaFactory", ex);
        }

        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                logger.info("Shutdown Hook is running !");
            }
        });
    }
}
