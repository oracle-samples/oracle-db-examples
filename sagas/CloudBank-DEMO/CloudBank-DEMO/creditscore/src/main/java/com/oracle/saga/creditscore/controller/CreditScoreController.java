/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.creditscore.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.saga.creditscore.data.CreditScoreDTO;
import com.oracle.saga.creditscore.exception.CreditScoreException;
import com.oracle.saga.creditscore.stubs.CreditScoreService;
import com.oracle.saga.creditscore.util.ConnectionPools;
import com.oracle.saga.creditscore.util.PropertiesHelper;
import jakarta.annotation.PreDestroy;
import jakarta.inject.Singleton;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.json.JsonReader;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import oracle.saga.SagaException;
import oracle.saga.SagaMessageContext;
import oracle.saga.SagaParticipant;
import oracle.saga.annotation.*;
import oracle.sql.json.OracleJsonException;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonParser;
import org.eclipse.microprofile.lra.annotation.Compensate;
import org.eclipse.microprofile.lra.annotation.Complete;
import org.ehcache.CacheManager;
import org.ehcache.config.builders.CacheConfigurationBuilder;
import org.ehcache.config.builders.CacheManagerBuilder;
import org.ehcache.config.builders.ResourcePoolsBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Reader;
import java.io.StringReader;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;

/**
 * CreditScoreController is the controller class for the respective Participant.
 * @Participant annotation needs to be mentioned to map the class to the respective participant.
 * SagaParticipant needs to be extended for this class to support Oracle Saga Annotations.
 */
@Path("/")
@Singleton
@Participant(name = "CreditScore")
public class CreditScoreController extends SagaParticipant {

    private static final String REG_EXP_REMOVE_QUOTES = "(^\")|(\"$)";
    private static final String FAILURE = "{\"result\":\"failure\"}";

    private static final Logger logger = LoggerFactory.getLogger(CreditScoreController.class);
    private static final String STATUS = "status";

    public static final String ACCEPTED = "Accepted";
    public static final String RESPONSE_IS = "The response: {}";

    final CacheManager cacheManager;

    /**
     * Constructor to initialize the cache and set different values.
     */
    public CreditScoreController() throws SagaException {
        var p = PropertiesHelper.loadProperties();
        var cacheSize = Integer.parseInt(p.getProperty("cacheSize", "100000"));
        cacheManager = CacheManagerBuilder.newCacheManagerBuilder().build(true);
        cacheManager.createCache("creditScoreCompensationData",
                CacheConfigurationBuilder.newCacheConfigurationBuilder(String.class,
                        ArrayList.class, ResourcePoolsBuilder.heap(cacheSize)));
        
    }

    /**
     * The PreDestroy annotation is used on a method as a callback notification to
     * signal that the instance is in the process of being removed by the container.
     */
    @Override
    @PreDestroy
    public void close() {
        try {
            logger.debug("Shutting down CreditScore Controller");
            super.close();
        } catch (SagaException e) {
            logger.error("Unable to shutdown initiator");
        }
    }

    /**
     * Indicates that the annotated method responds to HTTP GET requests.
     */
    @GET
    @Path("version")
    public Response getVersion() {
        return Response.status(Response.Status.OK.getStatusCode()).entity("1.0").build();
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("validateCreditScore")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response validateCreditScore(@QueryParam("invokeError") String invokeError, CreditScoreDTO payload) {
        
        Response response;
        var obj = new ObjectMapper();
        boolean validateOssn = Boolean.FALSE;

        try (var conn = ConnectionPools.getCreditScoreConnection()) {
            validateOssn = CreditScoreService.validateOssn(conn,payload);
        } catch (SQLException ex) {
            logger.error("Error validating customer!!!");
        }

        var rpayload = obj.createObjectNode();
        if(validateOssn){
            rpayload.put(STATUS, ACCEPTED);
            response = Response.status(Response.Status.ACCEPTED).entity(rpayload.toString()).build();
        }else{
            rpayload.put(STATUS, "Rejected");
            response = Response.status(Response.Status.FORBIDDEN).entity(rpayload.toString()).build();
        }
        logger.debug(RESPONSE_IS, response);
        
        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("viewCreditScore")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response viewCreditScore(@QueryParam("invokeError") String invokeError, CreditScoreDTO payload) {
        
        Response response;
        var obj = new ObjectMapper();
        String creditScore = null;

        try (var conn = ConnectionPools.getCreditScoreConnection()) {
            creditScore = CreditScoreService.viewCreditScore(conn,payload);
        } catch (SQLException ex) {
            logger.error("Error viewing credit score!!!");
        }

        var rpayload = obj.createObjectNode();
        if(creditScore!=null){
            rpayload.put(STATUS, ACCEPTED);
            rpayload.put("result", "success");
            rpayload.put("credit_score",creditScore);
            response = Response.status(Response.Status.ACCEPTED).entity(rpayload.toString()).build();
        }else{
            rpayload.put(STATUS, "Rejected");
            rpayload.put("result", "failure");
            response = Response.status(Response.Status.FORBIDDEN).entity(rpayload.toString()).build();
        }


        logger.debug(RESPONSE_IS, response);
        return response;
    }

    /**
     * If a resource method executes in the context of an LRA and if the containing class has a method annotated
     * with @Compensate then this method will be invoked if the LRA is cancelled.
     */
    @Compensate
    public void onPostRollback(SagaMessageContext info) {
        Connection connection = null;

        try {
            connection = info.getConnection();
        } catch (SagaException e) {
            logger.error("Unable to get database connection for credit score service");
        }

        try {

            var creditScore = new CreditScoreService(connection, this.cacheManager);
            if (!creditScore.updateBookRollback(info.getSagaId())) {
                logger.error("Unable to update credit_score_book");
            } else {
                logger.debug("Saga_ID was sucessfully updated");
            }
        } catch ( com.oracle.saga.creditscore.exception.CreditScoreException e) {
            logger.error("Credit Score Response");
        }
    }

    /**
     * @interface BeforeComplete
     * Any method annotated with @BeforeComplete will be invoked during saga finalization before a saga is committed.
     * The method annotated with @BeforeComplete is invoked before automatic completion for any lockless reservations performed by the saga.
     * The use of @BeforeComplete is optional.
     */
    @BeforeComplete
    public void onPreCommit(SagaMessageContext info) {
        Connection connection = null;

        try {
            connection = info.getConnection();
        } catch (SagaException e) {
            logger.error("Unable to get database connection for credit score service");
        }

        try {

            var creditScore = new CreditScoreService(connection, this.cacheManager);
            if (!creditScore.updateBookPreCommit(info.getSagaId())) {
                logger.error("Unable to update credit_score_book");
            } else {
                logger.debug("Saga_ID was sucessfully updated");
            }
        } catch (CreditScoreException e) {
            logger.error("Credit Score Response");
        }
    }

    /**
     * @interface InviteToJoin
     * Defined by a participant, this method will be invoked when the initiator requests that this participant join a given saga (via Saga.sendRequest(java.lang.String, java.lang.String)).
     * If the method returns true, the participant joins the saga.
     * Otherwise, a negative acknowledgement is returned, and Reject is invoked.
     * The use of @InviteToJoin is optional
     */
    @InviteToJoin
    public boolean onInviteToJoin(SagaMessageContext info) {
        logger.info("Joining saga: {}", info.getSagaId());
        return true;
    }

    /**
     * If a resource method executes in the context of an LRA and if the containing class has a method annotated
     * with @Complete (as well as method annotated with @Compensate) then this Complete method will be invoked
     * if the LRA is closed.
     */
    @Complete
    public void onPostCommit(SagaMessageContext info) {
        logger.debug("After Commit from {} for {}", info.getSender(), info.getSagaId());
    }

    /**
     * @interface BeforeCompensate
     * Any method annotated with @BeforeCompensate will be invoked during saga finalization before a saga is rolled back.
     * The method annotated with @BeforeCompensate is invoked before automatic compensation for any lockless reservations performed by the saga.
     * The use of @BeforeCompensate is optional.
     */
    @BeforeCompensate
    public void onPreRollback(SagaMessageContext info) {
        logger.debug("Before Rollback from {} for {}", info.getSender(), info.getSagaId());
    }

    /**
     * @interface Request
     * The @Request annotation is used to annotate a method that receives incoming requests from saga initiators.
     * The saga framework provides a SagaMessageContext object as an input to the annotated method.
     * If the participant is working with multiple initiators, an optional sender attribute can be specified (regular expressions are allowed) to differentiate between them.
     */
    @Request(sender = "CloudBank")
    public String onRequestCloudBank(SagaMessageContext info) {
        Connection connection = null;
        String status = FAILURE;

        try {
            connection = info.getConnection();
        } catch (SagaException e) {
            logger.error("Unable to get database connection for Credit Score");
        }

        CreditScoreService credit;
        try {
            credit = new CreditScoreService(connection, this.cacheManager);

            String creditScoreAction = parseCreditScoreAction(info.getPayload());

            if (creditScoreAction.equals("credit_check")) {
                var creditScore = credit.viewCreditScore(info.getPayload());
                if (creditScore != -1) {
                    status = "{\"result\":\"success\", \"credit_score\":\"" + creditScore + "\"}";
                    var cs = new CreditScoreService(connection, this.cacheManager);
                    cs.updateBookNewEnquiry(info.getPayload(), info.getSagaId());
                }
            } else {
                logger.error("Invalid credit score action specified: {}", creditScoreAction);
            }
        } catch (CreditScoreException e) {
            logger.error("Unable to start credit score service");
        }

        JsonObject jsonObject;
        try(JsonReader reader = Json.createReader(new java.io.StringReader(status))){
            jsonObject = reader.readObject();
        }
        var jsonObjectBuilder = Json.createObjectBuilder(jsonObject).add("participant", "CreditScore");
        var updatedJsonObject = jsonObjectBuilder.build();
        status=updatedJsonObject.toString();

        return status;
    }

    /**
     * parseAccountsAction is used to fetch requested account action from the request JSON.
     */
    private String parseCreditScoreAction(String payload) {
        Reader inputReader = new StringReader(payload);
        var jsonFactory = new OracleJsonFactory();
        var creditScoreAction = "";

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject currentJsonObj = parser.getObject();
            creditScoreAction = currentJsonObj.get("credit_operation_type").toString()
                    .replaceAll(REG_EXP_REMOVE_QUOTES, "").toLowerCase();
        } catch (OracleJsonException ex) {
            logger.error("Unable to parse payload");
        }
        return creditScoreAction;
    }
}
