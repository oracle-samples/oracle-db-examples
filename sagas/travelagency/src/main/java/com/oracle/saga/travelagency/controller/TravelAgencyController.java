/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.controller;

import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;

import java.io.PrintWriter;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.URI;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Properties;

import org.eclipse.microprofile.lra.annotation.Compensate;
import org.eclipse.microprofile.lra.annotation.Complete;
import org.eclipse.microprofile.lra.annotation.ws.rs.LRA;
import org.ehcache.Cache;
import org.ehcache.CacheManager;
import org.ehcache.config.builders.CacheConfigurationBuilder;
import org.ehcache.config.builders.CacheManagerBuilder;
import org.ehcache.config.builders.ResourcePoolsBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.oracle.saga.travelagency.data.BookingDto;
import com.oracle.saga.travelagency.data.TravelAgencySagaInfo;
import com.oracle.saga.travelagency.util.ConnectionPools;
import com.oracle.saga.travelagency.util.Constants;
import com.oracle.saga.travelagency.util.PropertiesHelper;

import jakarta.annotation.PreDestroy;
import jakarta.inject.Singleton;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.xml.bind.DatatypeConverter;
import oracle.saga.Saga;
import oracle.saga.SagaException;
import oracle.saga.SagaInitiator;
import oracle.saga.SagaMessageContext;
import oracle.saga.annotation.BeforeCompensate;
import oracle.saga.annotation.BeforeComplete;
import oracle.saga.annotation.InviteToJoin;
import oracle.saga.annotation.Participant;
import oracle.saga.annotation.Request;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonParser;

@Path("/")
@Singleton
@Participant(name = "TravelAgency")
public class TravelAgencyController extends SagaInitiator {
    private static final Logger logger = LoggerFactory.getLogger(TravelAgencyController.class);

    private static final String STATUS = "status";

    private int participantCount;

    private CacheManager cacheManager;
    private Cache<String, TravelAgencySagaInfo> travelAgencySagaCache;

    private int maxStatusWait;

    private boolean finalize = true;

    public TravelAgencyController() throws SagaException, SQLException {
        Properties p = PropertiesHelper.loadProperties();

        this.finalize = Boolean.parseBoolean(p.getProperty("finalize", "true"));
        logger.debug("finalize: {}", this.finalize);

        int cacheSize = Integer.parseInt(p.getProperty("cacheSize", "100000"));
        logger.debug("cache size: {}", cacheSize);

        cacheManager = CacheManagerBuilder.newCacheManagerBuilder().build(true);
        travelAgencySagaCache = cacheManager.createCache("travelAgencySaga",
                CacheConfigurationBuilder.newCacheConfigurationBuilder(String.class,
                        TravelAgencySagaInfo.class, ResourcePoolsBuilder.heap(cacheSize)));

        this.participantCount = 2;

        this.maxStatusWait = Integer.parseInt(p.getProperty("maxStatusWait", "60000"));
        logger.debug("maxStatusWait = {}", this.maxStatusWait);
    }

    @Override
    @PreDestroy
    public void close() {
        try {
            logger.debug("Shutting down Travel Agency Controller");
            super.close();
        } catch (SagaException e) {
            logger.error("Unable to shutdown initiator", e);
        }
    }

    @GET
    @Path("version")
    public Response getVersion() {
        return Response.status(Response.Status.OK.getStatusCode()).entity("1.0").build();
    }

    /**
     * Post to initiate booking request from travel agency for airline and car rental services.
     * 
     * @param invokeError    Query parameter with a value of either true or false to indicate if an
     *                       error should be invoked during testing.
     * @param bookingPayload Payload containing the booking information for airline and car service.
     *                       The payload should resemble format below: 
     *                       //@formatter:off
                             {
                                "flight": {
                                    "action": "Booking",
                                    "passengers": [
                                        {
                                            "firstName": "Jack",
                                            "lastName": "Frost",
                                            "birthdate": "1992-02-10",
                                            "gender": "F",
                                            "email": "sbt@yahoo.com",
                                            "phonePrimary": "949-767-9979",
                                            "flightId": "251",
                                            "seatType": "ECONOMY_SEATS",
                                            "seatNumber": "23A"
                                        },
                                        {
                                            "firstName": "Sam",
                                            "lastName": "Frost",
                                            "birthdate": "1990-08-30",
                                            "gender": "M",
                                            "email": "snua@yahoo.com",
                                            "phonePrimary": "949-767-9967",
                                            "flightId": "251",
                                            "seatType": "ECONOMY_SEATS",
                                            "seatNumber": "23B"
                                        }
                                    ]
                                },
                                "car": {
                                    "action": "Booking",
                                    "customer": "John Case",
                                    "phone": "898-908-9080",
                                    "driversLicense": "B189391",
                                    "birthdate": "1976-03-04",
                                    "startDate": "2022-04-05",
                                    "endDate": "2022-04-15",
                                    "carType": "Van"
                                }
                             }
                             //@formatter:on
     * 
     * @return
     */
    @LRA(end = false)
    @POST
    @Path("booking")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response booking(@QueryParam("invokeError") String invokeError,
            @HeaderParam(LRA_HTTP_CONTEXT_HEADER) URI lraId, BookingDto bookingPayload) {
        logger.info("booking with saga id: {}", lraId);
        Response response;
        ObjectMapper obj = new ObjectMapper();
        long requestStart = 0;
        long requestEnd = 0;
        long getSagaStart = 0;
        long getSagaEnd = 0;
        long start1 = 0;
        long end1 = 0;

        ArrayList<Long> sendRequestTimes = new ArrayList<>();

        requestStart = System.currentTimeMillis();
        logger.debug("Booking Request: {}", bookingPayload);
        logger.debug("Incoming header lra id: {}", lraId);

        TravelAgencySagaInfo sagaInfo = new TravelAgencySagaInfo();
        String checkInvokeErrorParam = invokeError;
        sagaInfo.setInvokeError(
                checkInvokeErrorParam != null && checkInvokeErrorParam.contentEquals("true"));

        String sagaId = lraId.toString();
        try {

            getSagaStart = System.currentTimeMillis();
            Saga saga = this.getSaga(sagaId);
            logger.debug("Booking saga id: {}", sagaId);
            getSagaEnd = System.currentTimeMillis();

            logger.debug("SagaId Created: {}", sagaId);
            sagaInfo.setSagaId(sagaId);

            travelAgencySagaCache.put(sagaId, sagaInfo);

            if (bookingPayload.getFlight() != null) {

                start1 = System.currentTimeMillis();
                saga.sendRequest("AIRLINE", bookingPayload.getFlight().toString());
                end1 = System.currentTimeMillis();
                sendRequestTimes.add(end1 - start1);

            }

            if (bookingPayload.getCar() != null) {
                start1 = System.currentTimeMillis();
                saga.sendRequest("CAR", bookingPayload.getCar().toString());
                end1 = System.currentTimeMillis();
                sendRequestTimes.add(end1 - start1);
            }

            ObjectNode payload = obj.createObjectNode();
            payload.put(STATUS, "Accepted");
            payload.put("status_url", "/travelagency/status/" + sagaId);
            payload.put("id", sagaId);

            response = Response.status(Response.Status.ACCEPTED).entity(payload.toString()).build();
            logger.debug("The response: {}", response);
            requestEnd = System.currentTimeMillis();

            logger.debug("Status of {} returned, rt: {}, gs: {}, sr: {}", Response.Status.ACCEPTED,
                    requestEnd - requestStart, getSagaEnd - getSagaStart, sendRequestTimes);

        } catch (SagaException e1) {
            logger.error("Booking Error", e1);
            response = Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
            logger.debug("Status of {} returned.", Response.Status.INTERNAL_SERVER_ERROR);
        }

        return response;
    }

    /**
     * Gets some overall saga stats
     * 
     * @return
     */
    @GET
    @Path("stats")
    @Produces(MediaType.TEXT_PLAIN)
    public Response getSagaStats() {
        int status = Status.OK.getStatusCode();

        StringWriter writer = new StringWriter();
        PrintWriter printWriter = new PrintWriter(writer);

        String selectCmd = "with data as (\n"
                + "select a.*, (extract(day from (finalization_time - begin_time))*24*60*60) +\n"
                + "(extract(hour from (finalization_time - begin_time))*60*60) + (extract(minute from\n"
                + "(finalization_time - begin_time))*60) + (extract(second from (finalization_time - begin_time)))\n"
                + "total_sec from sys.saga$ a\n"
                + "where begin_time >= from_tz(to_timestamp('22-FEB-23 11.35.36.531750\n"
                + "AM','DD-MON-YY HH:MI:SS.FF AM'), 'UTC')\n" + "  )\n"
                + "select status, count(*), round(min(total_sec), 2) min,\n"
                + "            round(max(total_sec), 2) max,\n"
                + "            round(avg(total_sec), 2) avg,\n"
                + "            round(stddev(total_sec), 2) sd from data group by status order by status asc";

        try (Connection conn = ConnectionPools.getTravelAgencyConnection();

                PreparedStatement stmt = conn.prepareStatement(selectCmd)) {
            try (ResultSet rs = stmt.executeQuery()) {

                printWriter.printf("%9s %9s %9s %9s %9s %9s%n", STATUS, "count(*)", "min", "max",
                        "avg", "sd");

                while (rs.next()) {
                    printWriter.printf("%9s %9s %9s %9s %9s %9s%n", rs.getString(1),
                            rs.getString(2), rs.getString(3), rs.getString(4), rs.getString(5),
                            rs.getString(6));
                }
                logger.info("results:\n{}", writer);
            }

        } catch (SQLException e) {
            logger.error("stats error", e);
            status = Status.INTERNAL_SERVER_ERROR.getStatusCode();
        }

        return Response.status(status).entity(writer.toString()).build();
    }

    @GET
    @Path("status/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getTransactionStatusDetails(@PathParam("id") String id) {
        Response response = null;
        int status = -100;
        long diff = 0;

        String selectcmd = "SELECT status, begin_time FROM sys.saga$ WHERE ID = ? and PARTICIPANT = ?";

        try (Connection conn = ConnectionPools.getTravelAgencyConnection();
                PreparedStatement stmt = conn.prepareStatement(selectcmd)) {
            byte[] bytes = DatatypeConverter.parseHexBinary(id);
            stmt.setBytes(1, bytes);
            stmt.setString(2, "TRAVELAGENCY");

            try (ResultSet rs = stmt.executeQuery()) {

                rs.next();
                Timestamp createdTime = rs.getTimestamp("begin_time");
                diff = (System.currentTimeMillis() - createdTime.getTime());
                status = rs.getInt(STATUS);
                logger.debug("Difference: {} ms, creation={}", diff, createdTime);

            }

            /*
             * If the state is either done or error, return it. Otherwise check to see if we have
             * exceeded the max wait time. If we have, return a 504, otherwise return a 202 to let
             * the client keep looping.
             */
            if (status == Constants.TRANS_COMPLETED) {
                response = Response.ok().build();
            } else if (status == Constants.TRANS_ERROR) {
                response = Response.status(Response.Status.BAD_REQUEST).build();
            } else {
                if (diff > this.maxStatusWait) {
                    response = Response.status(Response.Status.GATEWAY_TIMEOUT).build();
                } else {
                    response = Response.accepted().build();
                }
            }
        } catch (SQLException ex) {
            logger.error("Get transaction status detail error", ex);
            response = Response.serverError().build();
        }

        return response;
    }

    @Complete
    public void onPostCommit(SagaMessageContext info) {
        logger.debug("After Commit from {} for {}", info.getSender(), info.getSagaId());
    }

    @Compensate
    public void onPostRollback(SagaMessageContext info) {
        logger.debug("After Rollback from {} for {}", info.getSender(), info.getSagaId());
    }

    @BeforeComplete
    public void onPreCommit(SagaMessageContext info) {
        logger.debug("Before Commit from {} for {}", info.getSender(), info.getSagaId());
    }

    @BeforeCompensate
    public void onPreRollback(SagaMessageContext info) {
        logger.debug("Before Rollback from {} for {}", info.getSender(), info.getSagaId());
    }

    public void onForget(SagaMessageContext info) {
        // Do nothing
    }

    @InviteToJoin
    public boolean onInviteToJoin(SagaMessageContext info) {
        logger.debug("TravelAgency received invite to join saga {}", info.getSagaId());
        return true;
    }

    public void onReject(SagaMessageContext info) {
        // Do nothing
    }

    @Request(sender = ".*")
    public String onRequest(SagaMessageContext info) {
        return null;
    }

    @oracle.saga.annotation.Response(sender = "Car")
    public void onResponseCar(SagaMessageContext info) {
        logger.debug("Response(Car) from {} for saga {}: {}", info.getSender(), info.getSagaId(),
                info.getPayload());
        handleResponse(info);
    }

    @oracle.saga.annotation.Response(sender = "Airline.*")
    public void onResponseAir(SagaMessageContext info) {
        logger.debug("Response(Air) from {} for saga {}: {}", info.getSender(), info.getSagaId(),
                info.getPayload());
        handleResponse(info);
    }

    /**
     * Handle the response from a participant. If we get a negative response from any participant,
     * we will rollback the saga. If we get positive responses from all participants, we will commit
     * the saga.
     * 
     * @param info The response from the participant
     */
    public void handleResponse(SagaMessageContext info) {
        Saga saga = null;

        TravelAgencySagaInfo sagaInfo = null;
        Cache<String, TravelAgencySagaInfo> cachedSagaInfo = cacheManager
                .getCache("travelAgencySaga", String.class, TravelAgencySagaInfo.class);
        try {
            sagaInfo = cachedSagaInfo.get(info.getSagaId());
            saga = info.getSaga();
        } catch (Exception e) {
            logger.error("Error in handling response", e);
        }

        if (saga != null && sagaInfo != null) {

            sagaInfo.addReply(info.getSender());

            Reader inputReader = new StringReader(info.getPayload());
            OracleJsonFactory factory = new OracleJsonFactory();
            try (OracleJsonParser parser = factory.createJsonTextParser(inputReader)) {
                parser.next();
                OracleJsonObject currentJsonObj = parser.getObject();
                String result = currentJsonObj.get("result").toString().replaceAll("(^\")|(\"$)",
                        "");

                if (!result.equals("success") && !sagaInfo.getRollbackPerformed()) {
                    try {
                        logger.debug("Rollingback Saga [{}]", info.getSagaId());
                        saga.rollbackSaga();
                        sagaInfo.setRollbackPerformed(true);
                    } catch (SagaException e) {
                        logger.error("Unable to rollback after encountering error in response", e);
                    }

                }

                // If all the participants that have participated are done commit the saga.
                if (sagaInfo.getReplies().size() == this.participantCount
                        && !sagaInfo.getRollbackPerformed()) {

                    if (!this.finalize) {
                        cachedSagaInfo.remove(info.getSagaId());
                        return;
                    }

                    try {
                        if (!sagaInfo.getInvokeError()) {
                            logger.info("Committing Saga [{}]", info.getSagaId());
                            saga.commitSaga();
                        } else {
                            logger.info("Intentionally Causing a Rollback for Saga [{}]",
                                    info.getSagaId());
                            saga.rollbackSaga();
                            sagaInfo.setRollbackPerformed(true);
                        }
                    } catch (SagaException e) {
                        logger.error("Unable to finalize", e);
                    }
                    cachedSagaInfo.remove(info.getSagaId());
                } else {
                    logger.debug("{}: replies:{}, getInvokeError[{}] getRollbackPerformed[{}] ",
                            info.getSagaId(), sagaInfo.getReplies(), sagaInfo.getInvokeError(),
                            sagaInfo.getRollbackPerformed());
                }
            } catch (Exception e1) {
                logger.error("Unknown error", e1);
                try {
                    saga.rollbackSaga();
                } catch (SagaException e) {
                    logger.error("Unable to rollback after encountering error", e);
                }
                cachedSagaInfo.remove(info.getSagaId());
            }

        } else {
            if (saga == null) {
                logger.error("Saga is null for: {} ", info.getSagaId());
            }
            if (sagaInfo == null) {
                logger.error("SagaInfo is null for: {} ", info.getSagaId());
            }
        }
    }

}
