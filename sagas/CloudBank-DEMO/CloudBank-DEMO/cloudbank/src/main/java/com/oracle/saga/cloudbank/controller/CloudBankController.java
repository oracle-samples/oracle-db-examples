/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.cloudbank.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.saga.cloudbank.data.*;
import com.oracle.saga.cloudbank.stubs.Stubs;
import com.oracle.saga.cloudbank.util.ConnectionPools;
import com.oracle.saga.cloudbank.util.PropertiesHelper;
import jakarta.annotation.PreDestroy;
import jakarta.inject.Singleton;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;
import jakarta.json.JsonReader;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import oracle.saga.Saga;
import oracle.saga.SagaException;
import oracle.saga.SagaInitiator;
import oracle.saga.SagaMessageContext;
import oracle.saga.annotation.*;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonParser;
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

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;

/**
 * CloudBankController is the controller class for the respective Participant.
 * @Participant annotation needs to be mentioned to map the class to the respective participant.
 * SagaParticipant needs to be extended for this class to support Oracle Saga Annotations.
 */
@Path("/")
@Singleton
@Participant(name = "CloudBank")
public class CloudBankController extends SagaInitiator {
    private static final Logger logger = LoggerFactory.getLogger(CloudBankController.class);
    private static final String STATUS = "status";
    private final CacheManager cacheManager;
    private final Cache<String, CloudBankSagaInfo> cloudBankSagaCache;


    /**
     * Constructor to initialize the cache and set different values.
     */
    public CloudBankController() throws SagaException {
        var p = PropertiesHelper.loadProperties();
        var cacheSize = Integer.parseInt(p.getProperty("cacheSize", "100000"));
        cacheManager = CacheManagerBuilder.newCacheManagerBuilder().build(true);
        cloudBankSagaCache = cacheManager.createCache(Stubs.CACHE_NAME,
                CacheConfigurationBuilder.newCacheConfigurationBuilder(String.class,
                        CloudBankSagaInfo.class, ResourcePoolsBuilder.heap(cacheSize)));
    }

    /**
     * The PreDestroy annotation is used on a method as a callback notification to
     * signal that the instance is in the process of being removed by the container.
     */
    @Override
    @PreDestroy
    public void close() {
        try {
            logger.debug("Shutting down CloudBank Controller");
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
    @Path("newCustomer")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response newCustomer(@QueryParam("invokeError") String invokeError, NewCustomerDTO payload) {
        Response response;
        var obj = new ObjectMapper();
        String loginId = null;
        Boolean validCustomer=Boolean.FALSE;

        var val =new ValidateCustomerCreditScoreDTO();
        val.setFullName(payload.getFullName());
        val.setOssn(payload.getOssn());

        try{
        var client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(new URI(Stubs.URL_VALIDATE_CUSTOMER_IN_CREDIT_SCORE_DB))
                .header(Stubs.CONTENT_TYPE, Stubs.HEADER_JSON)
                .POST(HttpRequest.BodyPublishers.ofString(val.toString()))
                .build();
            HttpResponse<String> apiResp = client.send(request, HttpResponse.BodyHandlers.ofString());

            if(Response.Status.ACCEPTED.getStatusCode() == apiResp.statusCode()){
                validCustomer=Boolean.TRUE;
            }
        } catch (IOException e) {
            logger.error("Error during HTTP call");
        } catch (URISyntaxException e) {
            logger.error("Error during HTTP call");
        } catch (InterruptedException e){
            logger.error("Error during HTTP call");
        }

        if(validCustomer.equals(Boolean.TRUE)){
            try (var conn = ConnectionPools.getCloudBankConnection()) {
                loginId = Stubs.createNewCustomer(conn, payload);
            } catch (SQLException ex) {
                logger.error("Error creating new customer!!!");
            }
        }

        var rpayload = obj.createObjectNode();
        if(loginId!=null){
            rpayload.put(STATUS, Stubs.ACCEPTED_STATUS);
            rpayload.put("login_id", loginId);
            response = Response.status(Response.Status.ACCEPTED).entity(rpayload.toString()).build();
        }else{
            rpayload.put(STATUS, "Rejected");
            if(!validCustomer.equals(Boolean.TRUE)){
                rpayload.put(Stubs.RESPONSE_REASON, "NOT IN CREDIT SCORE DB.");
            }
            response = Response.status(Response.Status.BAD_REQUEST).entity(rpayload.toString()).build();
        }
        logger.debug(Stubs.RESPONSE_IS, response);

        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("login")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response login(@QueryParam("invokeError") String invokeError, LoginDTO payload) {

        Response response;
        var obj = new ObjectMapper();
        LoginReplyDTO rplyQuery = null;
        String bank=null;
        JsonObjectBuilder jsonObjectBuilderMain = null;

        try (var conn = ConnectionPools.getCloudBankConnection()) {
                rplyQuery = Stubs.login(conn, payload);

            if(rplyQuery!=null){

            JsonObject jsonObject1;
            try(JsonReader reader = Json.createReader(new java.io.StringReader(rplyQuery.toString()))){
                jsonObject1 = reader.readObject();
            }
            jsonObjectBuilderMain = Json.createObjectBuilder(jsonObject1);

                bank = Stubs.getBankBasedOnUCID(conn, payload.getId());
            }else{
                response = Response.status(Response.Status.FORBIDDEN).build();
            }

                if(bank!=null){
                        var client1 = HttpClient.newHttpClient();
                        var pack1 = new ViewAllAccountsDTO();
                        pack1.setUcid(rplyQuery.getUcid());
                        HttpRequest request1;
                        if(bank.equalsIgnoreCase(Stubs.BANK_A)){
                            request1 = HttpRequest.newBuilder()
                                    .uri(new URI(Stubs.URL_VIEW_ALL_ACCOUNTS_BANK_A))
                                    .header(Stubs.CONTENT_TYPE, Stubs.HEADER_JSON)
                                    .POST(HttpRequest.BodyPublishers.ofString(pack1.toString()))
                                    .build();
                        }else{
                            request1 = HttpRequest.newBuilder()
                                    .uri(new URI(Stubs.URL_VIEW_ALL_ACCOUNTS_BANK_B))
                                    .header(Stubs.CONTENT_TYPE, Stubs.HEADER_JSON)
                                    .POST(HttpRequest.BodyPublishers.ofString(pack1.toString()))
                                    .build();
                        }
                        HttpResponse<String> apiResp1 = client1.send(request1, HttpResponse.BodyHandlers.ofString());

                        if(Response.Status.ACCEPTED.getStatusCode() == apiResp1.statusCode()){
                            JsonObject jsonObject2;
                            try(JsonReader reader = Json.createReader(new java.io.StringReader(apiResp1.body()))){
                                jsonObject2 = reader.readObject();
                            }
                            var jsonObjectBuildertemp = Json.createObjectBuilder(jsonObject2);
                            jsonObjectBuilderMain.addAll(jsonObjectBuildertemp);
                        }

                        var client2 = HttpClient.newHttpClient();
                        var pack2 =new ViewCreditScoreDTO();
                        pack2.setOssn(rplyQuery.getOssn());
                        HttpRequest request2 = HttpRequest.newBuilder()
                                .uri(new URI(Stubs.URL_VIEW_CREDIT_SCORE_IN_CREDIT_SCORE_DB))
                                .header(Stubs.CONTENT_TYPE, Stubs.HEADER_JSON)
                                .POST(HttpRequest.BodyPublishers.ofString(pack2.toString()))
                                .build();
                        HttpResponse<String> apiResp2 = client2.send(request2, HttpResponse.BodyHandlers.ofString());

                        if(Response.Status.ACCEPTED.getStatusCode() == apiResp2.statusCode()){
                            JsonObject jsonObject3;
                            try(JsonReader reader = Json.createReader(new java.io.StringReader(apiResp2.body()))){
                                jsonObject3 = reader.readObject();
                            }
                            var jsonObjectBuildertemp = Json.createObjectBuilder(jsonObject3);
                            jsonObjectBuilderMain.addAll(jsonObjectBuildertemp);
                        }

                        var finalJSON = jsonObjectBuilderMain.build();

                        var rpayload = obj.createObjectNode();
                        rpayload.put(STATUS, Stubs.ACCEPTED_STATUS);
                        rpayload.put("data", finalJSON.toString());
                        response = Response.status(Response.Status.ACCEPTED).entity(rpayload.toString()).build();
                        logger.debug(Stubs.RESPONSE_IS, response);
                }else{
                    response = Response.status(Response.Status.FORBIDDEN).build();
                }

        } catch (URISyntaxException | IOException | InterruptedException | SQLException e1) {
            logger.error("Login Viewing Error");
            response = Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
            logger.debug(Stubs.STATUS_OF, Response.Status.INTERNAL_SERVER_ERROR);
        }

        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("refresh")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response refresh(@QueryParam("invokeError") String invokeError, RefreshDTO payload) {

        Response response = null;
        var obj = new ObjectMapper();
        String bank =null;

        try {
                var jsonObjectBuilderMain = Json.createObjectBuilder();

                try (var conn = ConnectionPools.getCloudBankConnection()) {
                    bank = Stubs.getBankBasedOnUCID(conn, payload.getUcid());
                }

                if (bank != null) {
                        var client1 = HttpClient.newHttpClient();
                        var pack1 = new ViewAllAccountsDTO();
                        pack1.setUcid(payload.getUcid());
                        HttpRequest request1;
                        if (bank.equalsIgnoreCase(Stubs.BANK_A)) {
                            request1 = HttpRequest.newBuilder()
                                    .uri(new URI(Stubs.URL_VIEW_ALL_ACCOUNTS_BANK_A))
                                    .header(Stubs.CONTENT_TYPE, Stubs.HEADER_JSON)
                                    .POST(HttpRequest.BodyPublishers.ofString(pack1.toString()))
                                    .build();
                        } else {
                            request1 = HttpRequest.newBuilder()
                                    .uri(new URI(Stubs.URL_VIEW_ALL_ACCOUNTS_BANK_B))
                                    .header(Stubs.CONTENT_TYPE, Stubs.HEADER_JSON)
                                    .POST(HttpRequest.BodyPublishers.ofString(pack1.toString()))
                                    .build();
                        }
                        HttpResponse<String> apiResp1 = client1.send(request1, HttpResponse.BodyHandlers.ofString());

                        if (Response.Status.ACCEPTED.getStatusCode() == apiResp1.statusCode()) {
                            JsonObject jsonObject2;
                            try (JsonReader reader = Json.createReader(new java.io.StringReader(apiResp1.body()))) {
                                jsonObject2 = reader.readObject();
                            }
                            var jsonObjectBuildertemp = Json.createObjectBuilder(jsonObject2);
                            jsonObjectBuilderMain.addAll(jsonObjectBuildertemp);
                           }

                        var client2 = HttpClient.newHttpClient();
                        var pack2 = new ViewCreditScoreDTO();
                        pack2.setOssn(payload.getOssn());
                        HttpRequest request2 = HttpRequest.newBuilder()
                                .uri(new URI(Stubs.URL_VIEW_CREDIT_SCORE_IN_CREDIT_SCORE_DB))
                                .header(Stubs.CONTENT_TYPE, Stubs.HEADER_JSON)
                                .POST(HttpRequest.BodyPublishers.ofString(pack2.toString()))
                                .build();
                        HttpResponse<String> apiResp2 = client2.send(request2, HttpResponse.BodyHandlers.ofString());

                        if (Response.Status.ACCEPTED.getStatusCode() == apiResp2.statusCode()) {
                            JsonObject jsonObject3;
                            try (JsonReader reader = Json.createReader(new java.io.StringReader(apiResp2.body()))) {
                                jsonObject3 = reader.readObject();
                            }
                            var jsonObjectBuildertemp = Json.createObjectBuilder(jsonObject3);
                            jsonObjectBuilderMain.addAll(jsonObjectBuildertemp);
                          }

                        var finalJSON = jsonObjectBuilderMain.build();

                        var rpayload = obj.createObjectNode();
                        rpayload.put(STATUS, Stubs.ACCEPTED_STATUS);
                        rpayload.put("data", finalJSON.toString());
                        response = Response.status(Response.Status.ACCEPTED).entity(rpayload.toString()).build();
                        logger.debug(Stubs.RESPONSE_IS, response);

                } else {
                    response = Response.status(Response.Status.FORBIDDEN).build();
                }
        } catch (SQLException | URISyntaxException | IOException | InterruptedException e1) {
            logger.error("Login Viewing Error");
            response = Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
            logger.debug(Stubs.STATUS_OF, Response.Status.INTERNAL_SERVER_ERROR);
        }

        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP GET requests.
     */
    @GET
    @Path("notification")
    @Produces(MediaType.APPLICATION_JSON)
    public Response notification(@QueryParam("invokeError") String invokeError) {

        Response response;
        var obj = new ObjectMapper();
        String reply = null;

        try (var conn = ConnectionPools.getCloudBankConnection()) {
            reply = Stubs.getNotifications(conn);
        } catch (SQLException e) {
            logger.error("FETCH NOTIFICATIONS ERROR");
        }

            if(reply!=null) {
                var rpayload = obj.createObjectNode();
                rpayload.put(STATUS, Stubs.ACCEPTED_STATUS);
                rpayload.put("data", reply);
                rpayload.put("participant", "cloudbank");
                response = Response.status(Response.Status.ACCEPTED).entity(rpayload.toString()).build();
                logger.debug(Stubs.RESPONSE_IS, response);
            }else{
                response = Response.status(Response.Status.BAD_REQUEST).build();
            }

        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     * @LRA annotation indicates that this method starts a new saga.
     */
    @LRA(end = false)
    @POST
    @Path("newBankAccount")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response newBankAccount(@QueryParam("invokeError") String invokeError,
                                   @HeaderParam(LRA_HTTP_CONTEXT_HEADER) URI lraId, Accounts payload) {
        logger.info("Creating new account with saga id: {}", lraId);
        Response response;
        var obj = new ObjectMapper();
        var sagaInfo = new CloudBankSagaInfo();
        sagaInfo.setInvokeError(invokeError != null && invokeError.contentEquals("true"));
        var sagaId = lraId.toString();
        String bank =null;

        try (var conn = ConnectionPools.getCloudBankConnection()) {
            bank = Stubs.getBankBasedOnUCID(conn, payload.getUcid());
        } catch (SQLException e) {
            logger.error("FETCH bank ERROR");
        }

        try {
            var saga = this.getSaga(sagaId);
            logger.debug("New Bank Account saga id: {}", sagaId);
            sagaInfo.setSagaId(sagaId);
            sagaInfo.setNewBA(Boolean.TRUE);
            sagaInfo.setAccounts(Boolean.TRUE);
            sagaInfo.setRequestAccounts(payload);
            sagaInfo.setFromBank(bank);
            cloudBankSagaCache.put(sagaId, sagaInfo);
            logBookUpdateCLoudBank(sagaInfo, Stubs.PENDING, Stubs.NEW_ACCOUNT);

            if(bank!=null){
                if(bank.equalsIgnoreCase(Stubs.BANK_A)){
                    saga.sendRequest(Stubs.BANK_A, payload.toString());
                }else{
                    saga.sendRequest(Stubs.BANK_B, payload.toString());
                }

            }

            var finalPayload = obj.createObjectNode();
            finalPayload.put(STATUS, Stubs.ACCEPTED_STATUS);
            finalPayload.put(Stubs.RESPONSE_REASON, "Your new account is being created. You will receive a notification once its created.");
            finalPayload.put("id", sagaId);
            response = Response.status(Response.Status.ACCEPTED).entity(finalPayload.toString()).build();
            logger.debug(Stubs.RESPONSE_IS, response);
            logBookUpdateCLoudBank(sagaInfo, Stubs.ONGOING, Stubs.NEW_ACCOUNT);
        } catch (SagaException e1) {
            logger.error("NEW ACCOUNT CREATION ERROR");
            response = Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
            logger.debug(Stubs.STATUS_OF, Response.Status.INTERNAL_SERVER_ERROR);
            logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.NEW_ACCOUNT);
        }
        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     * @LRA annotation indicates that this method starts a new saga.
     */
    @LRA(end = false)
    @POST
    @Path("newCreditCard")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response newCreditCard(@QueryParam("invokeError") String invokeError,
                                   @HeaderParam(LRA_HTTP_CONTEXT_HEADER) URI lraId, Accounts payload) {
        logger.info("Creating new credit card with saga id: {}", lraId);
        Response response;
        var obj = new ObjectMapper();
        var sagaInfo = new CloudBankSagaInfo();
        sagaInfo.setInvokeError(invokeError != null && invokeError.contentEquals("true"));
        var sagaId = lraId.toString();
        try {
            var saga = this.getSaga(sagaId);
            logger.debug("New CreditCard saga id: {}", sagaId);
            sagaInfo.setSagaId(sagaId);
            sagaInfo.setNewCC(Boolean.TRUE);
            sagaInfo.setAccounts(Boolean.TRUE);
            sagaInfo.setRequestAccounts(payload);
            sagaInfo.setCreditscoreresponse(Boolean.FALSE);
            sagaInfo.setAccountsResponse(Boolean.FALSE);
            sagaInfo.setAccountsSecondResponse(Boolean.FALSE);

            logBookUpdateCLoudBank(sagaInfo, Stubs.PENDING, Stubs.NEW_CREDIT_CARD);
            String ossn = null;
            String bank = null;

            try (var conn = ConnectionPools.getCloudBankConnection()) {
                ossn = Stubs.fetchOssnByUCID(conn, payload);
                bank = Stubs.getBankBasedOnUCID(conn, payload.getUcid());
            }

            sagaInfo.setFromBank(bank);
            cloudBankSagaCache.put(sagaId, sagaInfo);

            if(ossn != null ){
                if(bank!=null){
                    if(bank.equalsIgnoreCase(Stubs.BANK_A)){
                        saga.sendRequest(Stubs.BANK_A, payload.toString());
                    }else{
                        saga.sendRequest(Stubs.BANK_B, payload.toString());
                    }

                }
                var creditscoreRequest = obj.createObjectNode();
                creditscoreRequest.put("credit_operation_type","credit_check");
                creditscoreRequest.put("ossn",ossn);
                creditscoreRequest.put("ucid",payload.getUcid());
                saga.sendRequest("CreditScore", creditscoreRequest.toString());

                var finalPayload = obj.createObjectNode();
                finalPayload.put(STATUS, Stubs.ACCEPTED_STATUS);
                finalPayload.put(Stubs.RESPONSE_REASON, "Your new credit card request is being processed. You will receive an update shortly.");
                finalPayload.put("id", sagaId);
                response = Response.status(Response.Status.ACCEPTED).entity(finalPayload.toString()).build();
                logger.debug(Stubs.RESPONSE_IS, response);
                logBookUpdateCLoudBank(sagaInfo, Stubs.ONGOING, Stubs.NEW_CREDIT_CARD);

            }else{
                var finalPayload = obj.createObjectNode();
                finalPayload.put(STATUS, "Rejected");
                finalPayload.put(Stubs.RESPONSE_REASON, "Your new credit card request is denied. Ossn not available.");
                response = Response.status(Response.Status.FORBIDDEN).entity(finalPayload.toString()).build();
            }

        } catch (SagaException | SQLException e1) {
            logger.error("NEW CREDIT CARD ERROR");
            response = Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
            logger.debug(Stubs.STATUS_OF, Response.Status.INTERNAL_SERVER_ERROR);
            logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.NEW_CREDIT_CARD);
        }
        return response;
    }


    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     * @LRA annotation indicates that this method starts a new saga.
     */
    @LRA(end = false)
    @POST
    @Path("transfer")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response transfer(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) URI lraId, AccountTransferDTO payload) {
        logger.info("Starting new transfer with saga id: {}", lraId);
        Response response;
        var obj = new ObjectMapper();
        var sagaInfo = new CloudBankSagaInfo();
        var sagaId = lraId.toString();
        try {
            var saga = this.getSaga(sagaId);
            logger.debug("New transfer saga id: {}", sagaId);
            sagaInfo.setSagaId(sagaId);
            sagaInfo.setAccTransfer(Boolean.TRUE);
            sagaInfo.setAccounts(Boolean.TRUE);
            sagaInfo.setAccountTransferPayload(payload);
            sagaInfo.setDepositResponse(Boolean.FALSE);
            sagaInfo.setWithdrawResponse(Boolean.FALSE);

            String bank = null;
            Boolean same = Boolean.FALSE;

            try (var conn = ConnectionPools.getCloudBankConnection()) {
                bank = Stubs.getBankBasedOnUCID(conn, payload.getUcid());
                same = Stubs.bankCompare(bank,payload.getToAccountNumber());
            }

            sagaInfo.setFromBank(bank);
            if(bank!=null){
                if(same.equals(Boolean.TRUE)){
                    sagaInfo.setToBank(bank);
                }else{
                    if(bank.equalsIgnoreCase(Stubs.BANK_A)){
                        sagaInfo.setToBank(Stubs.BANK_B);
                    }else{
                        sagaInfo.setToBank(Stubs.BANK_A);
                    }
                }
            }

            cloudBankSagaCache.put(sagaId, sagaInfo);
            logBookUpdateCLoudBank(sagaInfo, Stubs.PENDING, Stubs.TRANSFER);

            try (var conn = ConnectionPools.getCloudBankConnection()) {
                if(Stubs.verifyUserForTransaction(conn,payload)){
                    JsonObject jsonObject;
                    try(JsonReader reader = Json.createReader(new java.io.StringReader(payload.toString()))){
                        jsonObject = reader.readObject();
                    }

                    if(same.equals(Boolean.TRUE)){
                        var jsonObjectBuildertemp = Json.createObjectBuilder(jsonObject).add(Stubs.OPERATIONTYPE,"TRANSACT");
                        if(bank!=null){
                            if(bank.equalsIgnoreCase(Stubs.BANK_A)){
                                saga.sendRequest(Stubs.BANK_A, jsonObjectBuildertemp.build().toString());
                            }else{
                                saga.sendRequest(Stubs.BANK_B, jsonObjectBuildertemp.build().toString());
                            }
                        }
                    }else{

                        if(bank!=null){
                            if(bank.equalsIgnoreCase(Stubs.BANK_A)){
                                var jsonObjectBuildertemp = Json.createObjectBuilder(jsonObject).add(Stubs.OPERATIONTYPE,Stubs.DEPOSIT).add(Stubs.TRANSACTIONTYPE,"CREDIT");
                                saga.sendRequest(Stubs.BANK_B, jsonObjectBuildertemp.build().toString());
                                var jsonObjectBuildertemp1 = Json.createObjectBuilder(jsonObject).add(Stubs.OPERATIONTYPE,Stubs.WITHDRAW).add(Stubs.TRANSACTIONTYPE,"DEBIT");
                                saga.sendRequest(Stubs.BANK_A, jsonObjectBuildertemp1.build().toString());
                            }else{
                                var jsonObjectBuildertemp = Json.createObjectBuilder(jsonObject).add(Stubs.OPERATIONTYPE,Stubs.DEPOSIT).add(Stubs.TRANSACTIONTYPE,"CREDIT");
                                saga.sendRequest(Stubs.BANK_A, jsonObjectBuildertemp.build().toString());
                                var jsonObjectBuildertemp1 = Json.createObjectBuilder(jsonObject).add(Stubs.OPERATIONTYPE,Stubs.WITHDRAW).add(Stubs.TRANSACTIONTYPE,"DEBIT");
                                saga.sendRequest(Stubs.BANK_B, jsonObjectBuildertemp1.build().toString());
                            }
                        }
                    }
                }
            }

            var finalPayload = obj.createObjectNode();
            finalPayload.put(STATUS, Stubs.ACCEPTED_STATUS);
            finalPayload.put(Stubs.RESPONSE_REASON, "Transfer process started. You will be updated shortly.");
            finalPayload.put("id", sagaId);
            response = Response.status(Response.Status.ACCEPTED).entity(finalPayload.toString()).build();
            logger.debug(Stubs.RESPONSE_IS, response);
            logBookUpdateCLoudBank(sagaInfo, Stubs.ONGOING, Stubs.TRANSFER);
        } catch (SagaException | SQLException e1) {
            logger.error("TRANSFER ERROR");
            response = Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
            logger.debug(Stubs.STATUS_OF, Response.Status.INTERNAL_SERVER_ERROR);
            logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.TRANSFER);
        }
        return response;
    }

    /**
     * If a resource method executes in the context of an LRA and if the containing class has a method annotated
     * with @Compensate then this method will be invoked if the LRA is cancelled.
     */
    @Compensate
    public void onPostRollback(SagaMessageContext info) {
        logger.debug("After Rollback from {} for {}", info.getSender(), info.getSagaId());
        CloudBankSagaInfo sagaInfo = null;
        Cache<String, CloudBankSagaInfo> cachedSagaInfo = cacheManager
                .getCache(Stubs.CACHE_NAME, String.class, CloudBankSagaInfo.class);
        
        sagaInfo = cachedSagaInfo.get(info.getSagaId());
        

        if(sagaInfo!=null){
            if(sagaInfo.isNewBA()){
                logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.NEW_ACCOUNT);
            }
            if(sagaInfo.isAccTransfer()){
                logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.TRANSFER);
            }
            if(sagaInfo.isNewCC()){
                logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.NEW_CREDIT_CARD);
            }
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
        logger.debug("Before Commit from {} for {}", info.getSender(), info.getSagaId());
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
        logger.debug("CloudBank received invite to join saga {}", info.getSagaId());
        return true;
    }

    /**
     * @interface Request
     * The @Request annotation is used to annotate a method that receives incoming requests from saga initiators.
     * The saga framework provides a SagaMessageContext object as an input to the annotated method.
     * If the participant is working with multiple initiators, an optional sender attribute can be specified (regular expressions are allowed) to differentiate between them.
     */
    @Request(sender = ".*")
    public String onRequest(SagaMessageContext info) {
        return null;
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
     * @interface Response
     * Initiators use the @Response annotation to annotate methods that collect responses from saga participants
     * enrolled into a saga using the Saga.sendRequest(java.lang.String, java.lang.String) API.
     * The saga framework provides a SagaMessageContext object as an input to the annotated method.
     * If the initiator is working with multiple participants, an optional sender attribute can be specified
     * (regular expressions are allowed) to differentiate between them.
     */
    @oracle.saga.annotation.Response(sender = "BankA.*")
    public void onResponseBankA(SagaMessageContext info) {
        logger.info("Response(BankA) from {} for saga {}: {}", info.getSender(), info.getSagaId(),
                info.getPayload());
        handleResponse(info);
    }

    /**
     * @interface Response
     * Initiators use the @Response annotation to annotate methods that collect responses from saga participants
     * enrolled into a saga using the Saga.sendRequest(java.lang.String, java.lang.String) API.
     * The saga framework provides a SagaMessageContext object as an input to the annotated method.
     * If the initiator is working with multiple participants, an optional sender attribute can be specified
     * (regular expressions are allowed) to differentiate between them.
     */
    @oracle.saga.annotation.Response(sender = "BankB.*")
    public void onResponseBankB(SagaMessageContext info) {
        logger.info("Response(BankB) from {} for saga {}: {}", info.getSender(), info.getSagaId(),
                info.getPayload());
        handleResponse(info);
    }

    /**
     * @interface Response
     * Initiators use the @Response annotation to annotate methods that collect responses from saga participants
     * enrolled into a saga using the Saga.sendRequest(java.lang.String, java.lang.String) API.
     * The saga framework provides a SagaMessageContext object as an input to the annotated method.
     * If the initiator is working with multiple participants, an optional sender attribute can be specified
     * (regular expressions are allowed) to differentiate between them.
     */
    @oracle.saga.annotation.Response(sender = "CreditScore.*")
    public void onResponseCreditScore(SagaMessageContext info) {
        logger.info("Response(CreditScore) from {} for saga {}: {}", info.getSender(), info.getSagaId(),
                info.getPayload());
        handleResponse(info);
    }

    /**
     * handleResponse is used to handle response received from  different participants.
     */
    public void handleResponse(SagaMessageContext info) {
        Saga saga = null;
        CloudBankSagaInfo sagaInfo = null;
        Cache<String, CloudBankSagaInfo> cachedSagaInfo = cacheManager
                .getCache(Stubs.CACHE_NAME, String.class, CloudBankSagaInfo.class);
        try {
            sagaInfo = cachedSagaInfo.get(info.getSagaId());
            if(!sagaInfo.isRollbackPerformed()){
                saga = info.getSaga();
            }else{
                logger.error("Saga {} Already Rolled Back", info.getSagaId());
            }
        } catch (SagaException e) {
            logger.error("Error in handling response");
        }

        if (saga != null) {
            sagaInfo.addReply(info.getSender());
            Reader inputReader = new StringReader(info.getPayload());
            var factory = new OracleJsonFactory();
            try (OracleJsonParser parser = factory.createJsonTextParser(inputReader)) {
                parser.next();
                OracleJsonObject currentJsonObj = parser.getObject();
                String result = currentJsonObj.get("result").toString().replaceAll(Stubs.REPLACE_STRING,"");

                if (!result.equals("success") ) {
                    if(!sagaInfo.isRollbackPerformed()){

                            logger.info("Rollingback Saga [{}]", info.getSagaId());
                            saga.rollbackSaga();
                            sagaInfo.setRollbackPerformed(true);

                    }else{
                        logger.info("Saga {} Already Rolled Back", info.getSagaId());
                    }
                }
                if(!sagaInfo.isRollbackPerformed()){
                    if(info.getSender().equalsIgnoreCase(Stubs.BANK_A) || info.getSender().equalsIgnoreCase(Stubs.BANK_B)){
                        if(sagaInfo.isAccountsResponse()){
                            sagaInfo.setAccountsSecondResponse(true);
                        }
                        sagaInfo.setAccountsResponse(true);
                    } else if (info.getSender().equalsIgnoreCase("creditscore")) {
                        sagaInfo.setCreditscoreresponse(true);
                    }
                }

                if(sagaInfo.isAccountsResponse() && sagaInfo.isNewBA() && !sagaInfo.isRollbackPerformed()){


                        if (!sagaInfo.isInvokeError()) {
                            logger.info(Stubs.COMMITTING_SAGA, info.getSagaId());
                            saga.commitSaga();
                            logBookUpdateCLoudBank(sagaInfo, Stubs.COMPLETED, Stubs.NEW_ACCOUNT);
                        } else {
                            logger.info(Stubs.ROLLBACK_INTENTIONAL,
                                    info.getSagaId());
                            saga.rollbackSaga();
                            sagaInfo.setRollbackPerformed(true);
                            logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.NEW_ACCOUNT);
                        }


                }else{
                    logger.debug("{}: replies:{}, getInvokeError[{}] getRollbackPerformed[{}] ",
                            info.getSagaId(), sagaInfo.getReplies(), sagaInfo.isInvokeError(),
                            sagaInfo.isRollbackPerformed());
                }

                if(sagaInfo.isAccountsResponse() && sagaInfo.isAccTransfer() && !sagaInfo.isRollbackPerformed()){
                    String operationType = currentJsonObj.get(Stubs.OPERATIONTYPE).toString().replaceAll(Stubs.REPLACE_STRING,"");
                    if(operationType.equals(Stubs.DEPOSIT)){
                        sagaInfo.setDepositResponse(Boolean.TRUE);
                    }else if (operationType.equals(Stubs.WITHDRAW)){
                        sagaInfo.setWithdrawResponse(Boolean.TRUE);
                    }else if( operationType.equalsIgnoreCase("TRANSACT")){
                        sagaInfo.setDepositResponse(Boolean.TRUE);
                        sagaInfo.setWithdrawResponse(Boolean.TRUE);
                    }

                    if(sagaInfo.getDepositResponse() && sagaInfo.getWithdrawResponse()){

                            if (!sagaInfo.isInvokeError()) {
                                logger.info(Stubs.COMMITTING_SAGA, info.getSagaId());
                                saga.commitSaga();
                                logBookUpdateCLoudBank(sagaInfo, Stubs.COMPLETED, Stubs.TRANSFER);
                            } else {
                                logger.info(Stubs.ROLLBACK_INTENTIONAL,
                                        info.getSagaId());
                                saga.rollbackSaga();
                                sagaInfo.setRollbackPerformed(true);
                                logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.TRANSFER);
                            }

                    }
                }else{
                    logger.debug("{}: replies:{}, getInvokeError[{}] getRollbackPerformed[{}] ",
                            info.getSagaId(), sagaInfo.getReplies(), sagaInfo.isInvokeError(),
                            sagaInfo.isRollbackPerformed());
                }

                if(sagaInfo.getCreditscoreresponse() && sagaInfo.isNewCC() && !sagaInfo.isAccountsResponse() && !sagaInfo.isRollbackPerformed() && !sagaInfo.isAccountsSecondResponse()){
                    logger.info("Credit Score Fetched. Waiting for Credit Card Creation.");
                    sagaInfo.setcSResponse(info.getPayload());
                }

                if(sagaInfo.isAccountsResponse() && sagaInfo.isNewCC() && !sagaInfo.isRollbackPerformed() && !sagaInfo.getCreditscoreresponse() && !sagaInfo.isAccountsSecondResponse()){
                    logger.info("Credit Card Created. Waiting for Credit Score Validation.");
                    sagaInfo.setAccountResponse(info.getPayload());
                }

                if(sagaInfo.getCreditscoreresponse() && sagaInfo.isNewCC() && sagaInfo.isAccountsResponse() && !sagaInfo.isRollbackPerformed() && sagaInfo.isAccountsSecondResponse()){

                        if (!sagaInfo.isInvokeError()) {
                            logger.info(Stubs.COMMITTING_SAGA, info.getSagaId());
                            saga.commitSaga();
                            logBookUpdateCLoudBank(sagaInfo, Stubs.COMPLETED, Stubs.NEW_CREDIT_CARD);
                        } else {
                            logger.info(Stubs.ROLLBACK_INTENTIONAL,
                                    info.getSagaId());
                            saga.rollbackSaga();
                            sagaInfo.setRollbackPerformed(true);
                            logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.NEW_CREDIT_CARD);
                        }

                }

                if(sagaInfo.getCreditscoreresponse() && sagaInfo.isNewCC() && sagaInfo.isAccountsResponse() && !sagaInfo.isRollbackPerformed() && !sagaInfo.isAccountsSecondResponse()){

                    var payload = sagaInfo.getRequestAccounts();

                    if(sagaInfo.getcSResponse()==null){
                        sagaInfo.setcSResponse(info.getPayload());
                    }
                    String balance = Stubs.setBalanceNewCC(sagaInfo.getcSResponse());
                    if(balance==null){
                        saga.rollbackSaga();
                        sagaInfo.setRollbackPerformed(true);
                        logBookUpdateCLoudBank(sagaInfo, Stubs.FAILED, Stubs.NEW_CREDIT_CARD);
                    }else{
                        if(sagaInfo.getAccountResponse()==null){
                            sagaInfo.setAccountResponse(info.getPayload());
                        }
                        Reader accountsResponse = new StringReader(sagaInfo.getAccountResponse());
                        var factoryAccountsResponse = new OracleJsonFactory();
                        try (OracleJsonParser parserAccountsResponse = factoryAccountsResponse.createJsonTextParser(accountsResponse)) {
                            parserAccountsResponse.next();
                            OracleJsonObject savedAccountsResponse = parserAccountsResponse.getObject();
                            payload.setAccountNumber(savedAccountsResponse.get("cc_number").toString().replaceAll(Stubs.REPLACE_STRING,""));
                        }
                        payload.setOperationType("NEW_CREDIT_CARD_SET_BALANCE");
                        payload.setBalanceAmount(balance);

                        if(sagaInfo.getFromBank().equalsIgnoreCase(Stubs.BANK_A)){
                            saga.sendRequest(Stubs.BANK_A, payload.toString());
                        }else{
                            saga.sendRequest(Stubs.BANK_B, payload.toString());
                        }
                    }
                }

            } catch (SagaException e1) {
                logger.error("Unknown error");
                try {
                    saga.rollbackSaga();
                } catch (SagaException e) {
                    logger.error("Unable to rollback after encountering error");
                }
                cachedSagaInfo.remove(info.getSagaId());
            }
        } else {
            logger.error("Saga is null for: {} ", info.getSagaId());
        }
    }

    /**
     * logBookUpdateCLoudBank is used to insert / update changes in the cloudbank_book
     */
    private void logBookUpdateCLoudBank(CloudBankSagaInfo sagaInfo, String state, String operationType) {

        var queryInsert = "INSERT INTO cloudbank_book (saga_id, ucid, operationType, operation_status, created_at, transfer_type) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP,?)";
        var queryUpdate = "UPDATE cloudbank_book set operation_status = ? where saga_id = ? ";

        try (var conn = ConnectionPools.getCloudBankConnection()){

            if(state.equals(Stubs.PENDING)){
                try (PreparedStatement insertStmt = conn.prepareStatement(queryInsert)) {
                    insertStmt.setString(1, sagaInfo.getSagaId());
                    switch (operationType) {
                        case Stubs.NEW_ACCOUNT:
                        case Stubs.NEW_CREDIT_CARD:
                            insertStmt.setString(2, sagaInfo.getRequestAccounts().getUcid());
                            break;
                        case Stubs.TRANSFER:
                            insertStmt.setString(2, sagaInfo.getAccountTransferPayload().getUcid());
                            break;
                        default:
                            break;
                    }

                    insertStmt.setString(3, operationType);
                    insertStmt.setString(4, state);
                    if(operationType.equalsIgnoreCase(Stubs.TRANSFER)){
                        if(sagaInfo.getFromBank().equalsIgnoreCase(sagaInfo.getToBank())){
                            insertStmt.setString(5, "INTRA-BANK");
                        }else{
                            insertStmt.setString(5, "INTER-BANK");
                        }
                    }else{
                        insertStmt.setString(5, "null");
                    }

                    insertStmt.executeUpdate();
                }
            }else {
                try (PreparedStatement updateStmt = conn.prepareStatement(queryUpdate)) {
                    updateStmt.setString(1, state);
                    updateStmt.setString(2, sagaInfo.getSagaId());

                    int rowsAffected = updateStmt.executeUpdate();

                    if(rowsAffected!=1){
                        logger.error("Unable to update sags status in cloudbank_book");
                    }
                }
            }
        } catch (SQLException e) {
            logger.error("Connection error logbookUpdateCloudBank");
        }
    }
}
