/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.airline;

import java.io.InputStream;
import java.io.Reader;
import java.io.StringReader;
import java.sql.Connection;
import java.util.List;
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

@Participant(name = "Airline")
public class Airline extends SagaParticipant {
    private static final Logger logger = LoggerFactory.getLogger(Airline.class);

    private CacheManager cacheManager;
    private static final String REG_EXP_REMOVE_QUOTES = "(^\")|(\"$)";
    private static final String FAILURE = "{\"result\":\"failure\"}";

    private Cache<String, CompensationData> cachedCompensationInfo;

    public Airline(CacheManager cache) throws SagaException {
        super(true);

        this.cacheManager = cache;
        this.cachedCompensationInfo = cacheManager.getCache("flightCompensationData", String.class,
                CompensationData.class);
    }

    public static void main(String[] args) throws Exception {
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
        cacheManager.createCache("flightCompensationData",
                CacheConfigurationBuilder.newCacheConfigurationBuilder(String.class,
                        CompensationData.class, ResourcePoolsBuilder.heap(cacheSize)));

        try {
            logger.info("Starting Airline");
            Airline airline = new Airline(cacheManager);
            airline.startWorkers();

            try (Scanner kbReader = new Scanner(System.in)) {
                String input = "";
                do {
                    System.out.println("Please Q or q to end application.");
                    input = kbReader.nextLine();
                } while (!input.equalsIgnoreCase("Q"));
            }

            logger.info("Airline shutting down.");
            airline.close();

        } catch (SagaException ex) {
            logger.error("Unable to instantiate airline", ex);
        }

        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                logger.debug("Shutdown Hook is running !");
            }
        });
    }

    @Complete
    public void onPostCommit(SagaMessageContext info) {
        logger.debug("Airline After Commit from {} for {}", info.getSender(), info.getSagaId());
    }

    @Compensate
    public void onPostRollback(SagaMessageContext info) {
        logger.debug("Airline After Rollback from {} for {} with payload {}", info.getSender(),
                info.getSagaId(), info.getPayload());

        Connection connection = null;

        long start = System.currentTimeMillis();
        long end = 0;

        try {
            connection = info.getConnection();
        } catch (SagaException e) {
            logger.error("Unable to get database connection for flight", e);
        }

        try {

            CompensationData flightCompensationInfo = cachedCompensationInfo.get(info.getSagaId());

            FlightService flight = new FlightService(connection, this.cacheManager);
            List<Integer> passengerIdList = flightCompensationInfo.getPersonIdList();

            flight.trackUnBookedSeatForFlights(flightCompensationInfo);

            if (!flight.rollbackInvalidFlightBooking(passengerIdList)) {
                logger.error("Unable to remove passenger {} from passenger list.", passengerIdList);

            } else {
                logger.debug("Passenger {} was successfully removed from passenter list.",
                        passengerIdList);
            }
        } catch (Exception e) {
            logger.error("Airline Response", e);
        } finally {
            cachedCompensationInfo.remove(info.getSagaId());
        }

        end = System.currentTimeMillis();
        logger.debug("Status of compensation, rt: {}", end - start);
    }

    @BeforeComplete
    public void onPreCommit(SagaMessageContext info) {
        logger.debug("Airline Before Commit from {} for {}", info.getSender(), info.getSagaId());

    }

    @BeforeCompensate
    public void onPreRollback(SagaMessageContext info) {
        logger.debug("Airline Before Rollback from {} for {}", info.getSender(), info.getSagaId());

    }

    @InviteToJoin
    public boolean onInviteToJoin(SagaMessageContext info) {
        logger.debug("Joining saga: {}", info.getSagaId());
        return true;
    }

    @Request(sender = "TravelAgency")
    public String handleTravelAgencyRequest(SagaMessageContext info) {
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

        FlightService flight;
        try {
            flight = new FlightService(connection, this.cacheManager);
            String flightAction = parseFlightAction(info.getPayload());

            switch (flightAction) {
            case "booking":
                if (flight.bookFlight(info.getPayload(), info.getSagaId())) {
                    status = "{\"result\":\"success\"}";
                }
                break;
            case "update":
                break;
            default:
                logger.error("Invalid flight action specified: {}", flightAction);
            }
        } catch (Exception e) {
            logger.error("Unable to create airline reservation", e);
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
    private String parseFlightAction(String payload) {
        Reader inputReader = new StringReader(payload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        String flightAction = "";

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject currentJsonObj = parser.getObject();
            flightAction = currentJsonObj.get("ACTION".toLowerCase()).toString()
                    .replaceAll(REG_EXP_REMOVE_QUOTES, "").toLowerCase();
        } catch (OracleJsonException ex) {
            logger.error("Unable to parse payload", ex);
        }

        return flightAction;
    }
}
