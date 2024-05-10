/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.banka.controller;

import com.oracle.saga.banka.data.BankValidateDTO;
import com.oracle.saga.banka.data.CompensationData;
import com.oracle.saga.banka.data.CreditResponse;
import com.oracle.saga.banka.data.ViewBADTO;
import com.oracle.saga.banka.stubs.AccountsService;
import com.oracle.saga.banka.util.ConnectionPools;
import com.oracle.saga.banka.util.PropertiesHelper;
import jakarta.annotation.PreDestroy;
import jakarta.inject.Singleton;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.json.JsonObjectBuilder;
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
import org.ehcache.Cache;
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
import java.util.Properties;

/**
 * AccountsController is the controller class for Participant.
 * @Participant needs to be mentioned to map the class to the respective participant.
 * SagaParticipant needs to be extended for this class to support Oracle Saga Annotations.
 */
@Path("/")
@Singleton
@Participant(name = "BankA")
public class AccountsController extends SagaParticipant {

    private static final String REG_EXP_REMOVE_QUOTES = "(^\")|(\"$)";
    private static final String FAILURE = "{\"result\":\"failure\"}";
    private static final Logger logger = LoggerFactory.getLogger(AccountsController.class);
    final CacheManager cacheManager;

    /**
     * Constructor to initialize the cache and set different values.
     */
    public AccountsController() throws SagaException {
        Properties p = PropertiesHelper.loadProperties();
        int cacheSize = Integer.parseInt(p.getProperty("cacheSize", "100000"));
        cacheManager = CacheManagerBuilder.newCacheManagerBuilder().build(true);
        cacheManager.createCache("bankACompensationData",
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
            logger.debug("Shutting down Bank A Controller");
            super.close();
        } catch (SagaException e) {
            logger.error("Unable to shutdown Bank A initiator");
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
     * If a resource method executes in the context of an LRA and if the containing class has a method annotated
     * with @Compensate then this method will be invoked if the LRA is cancelled.
     */
    @Compensate
    public void onPostRollback(SagaMessageContext info) {
        Connection connection = null;

        try {
            connection = info.getConnection();
        } catch (SagaException e) {
            logger.error("Unable to get database connection for Bank service");
        }

        try {
            Cache<String, ArrayList> cachedCompensationInfo;
            cachedCompensationInfo = cacheManager.getCache("bankACompensationData", String.class, ArrayList.class);

            if(cachedCompensationInfo.containsKey(info.getSagaId())){
                ArrayList<CompensationData> accountCompensationInfo = cachedCompensationInfo.get(info.getSagaId());
                AccountsService as =new AccountsService(connection,this.cacheManager);
                for(CompensationData account:accountCompensationInfo){
                    if(account.getOperationtype().equals("NEW_CREDIT_CARD") || account.getOperationtype().equals("NEW_BANK_ACCOUNT")){
                        boolean check = as.deleteAccount(account);
                        if (!check) {
                            logger.error("Unable to remove account {} from accounts.", account.getAccountnumber());
                        } else {
                            logger.debug("Account {} was successfully removed from accounts.",
                                    account.getAccountnumber());
                        }
                    }
                    as.updateOperationStatus(info.getSagaId(), AccountsService.FAILED);
                }
            }

        } catch (com.oracle.saga.banka.exception.AccountsException e) {
            logger.error("Bank A Response");
        }
    }

    /**
     * Any method annotated with @BeforeComplete will be invoked during saga finalization before a saga is committed.
     * The method annotated with @BeforeComplete is invoked before automatic completion for any lockless reservations performed by the saga.
     */
    @BeforeComplete
    public void onPreCommit(SagaMessageContext info) {
        logger.debug("Before Commit(SMC) from {} for {}", info.getSender(), info.getSagaId());
        Connection connection = null;

        long start = System.currentTimeMillis();
        long end;

        try {
            connection = info.getConnection();
        } catch (SagaException e) {
            logger.error("Unable to get database connection for accounts service");
        }

        try {
            AccountsService as =new AccountsService(connection, this.cacheManager);
            as.updateOperationStatus(info.getSagaId(),AccountsService.COMPLETED);

        } catch (com.oracle.saga.banka.exception.AccountsException e) {
            logger.error("Bank A Response");
        }

        end = System.currentTimeMillis();
        logger.debug("Status of compensation, rt: {}", end - start);
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
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("viewAccounts")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response viewAll(ViewBADTO payload) {
        
        Response response;
        String details = null;

        try (Connection conn = ConnectionPools.getAccountsConnection()) {
            details = AccountsService.viewAllAccounts(conn, payload, "ALL");
        } catch (SQLException ex) {
            logger.error(AccountsService.ERROR_VIEWING);
        }

        response = Response.status(Response.Status.ACCEPTED).entity(details).build();

        logger.debug(AccountsService.RESPONSE_IS, response);
        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("isInBank")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response viewAll(BankValidateDTO payload) {

        Response response;
        boolean isPresent = Boolean.FALSE;

        try (Connection conn = ConnectionPools.getAccountsConnection()) {
            isPresent = AccountsService.bankValidate(conn, payload);
        } catch (SQLException ex) {
            logger.error(AccountsService.ERROR_VIEWING);
        }
        response = Response.status(Response.Status.ACCEPTED).build();

        logger.debug(AccountsService.RESPONSE_IS, response);

        if(isPresent){
            response = Response.status(Response.Status.ACCEPTED).build();
        }else{
            response = Response.status(Response.Status.BAD_REQUEST).build();
        }
        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("viewBAC")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response viewBAC(ViewBADTO payload) {

        Response response;
        String details = null;

        try (Connection conn = ConnectionPools.getAccountsConnection()) {
            details = AccountsService.viewAllAccounts(conn, payload,"CHECKING");
        } catch (SQLException ex) {
            logger.error(AccountsService.ERROR_VIEWING);
        }

        response = Response.status(Response.Status.ACCEPTED).entity(details).build();

        logger.debug(AccountsService.RESPONSE_IS, response);
        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("viewBAS")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response viewBAS(ViewBADTO payload) {

        Response response;
        String details = null;

        try (Connection conn = ConnectionPools.getAccountsConnection()) {
            details = AccountsService.viewAllAccounts(conn, payload,"SAVING");
        } catch (SQLException ex) {
            logger.error("Error viewing accounts!!!");
        }

        response = Response.status(Response.Status.ACCEPTED).entity(details).build();

        logger.debug(AccountsService.RESPONSE_IS, response);
        return response;
    }

    /**
     * Indicates that the annotated method responds to HTTP POST requests.
     */
    @POST
    @Path("viewCC")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response viewCC(ViewBADTO payload) {

        Response response;
        String details = null;

        try (Connection conn = ConnectionPools.getAccountsConnection()) {
            details = AccountsService.viewAllAccounts(conn, payload,"CREDIT_CARD");
        } catch (SQLException ex) {
            logger.error("Error viewing accounts!!!");
        }

        response = Response.status(Response.Status.ACCEPTED).entity(details).build();

        logger.debug(AccountsService.RESPONSE_IS, response);
        return response;
    }


    /**
     * @interface Request
     * The @Request annotation is used to annotate a method that receives incoming requests from saga initiators.
     * The saga framework provides a SagaMessageContext object as an input to the annotated method.
     * If the participant is working with multiple initiators, an optional sender attribute can be specified (regular expressions are allowed) to differentiate between them.
     */
    @Request(sender = "CloudBank")
    public String onRequest(SagaMessageContext info) {

        Connection connection = null;

        String status = FAILURE;
        try {
            connection = info.getConnection();

        AccountsService account;
            account = new AccountsService(connection, this.cacheManager);

            String accountsAction = parseAccountsAction(info.getPayload());

            switch (accountsAction) {
            case "new_bank_account":
                String newAccount = account.newBankAccount(info.getPayload(), info.getSagaId());

                if(newAccount!=null){
                    status = "{\"result\":\"success\",\"account_number\":\""+newAccount+"\"}";
                }
                break;
            case "new_credit_card":
                CreditResponse resp = account.newCCAccount(info.getPayload(), info.getSagaId());

                if(resp!=null){
                    status = "{\"result\":\"success\",\"cc_number\":\""+resp.getAccountNumber()+"\",\"credit_limit\":\""+resp.getCreditLimit()+"\"}";
                }
                break;
            case "new_credit_card_set_balance":
                boolean state = account.updateCreditLimit(info.getPayload(), info.getSagaId());

                if(state){
                    status = "{\"result\":\"success\"}";
                }
                break;
            case "deposit":
                String depositStatus = account.depositMoney(info.getPayload(), info.getSagaId());
                status = "{\"result\":\"failure\",\"operationType\":\"DEPOSIT\"}";
                if(Double.parseDouble(depositStatus)!=-1){
                    status = AccountsService.RESULT_SUCCESS_IS+depositStatus+"\",\"operationType\":\"DEPOSIT\"}";
                }
                break;
            case "withdraw":
                String withdrawStatus = account.withdrawMoney(info.getPayload(), info.getSagaId());
                status = "{\"result\":\"failure\",\"operationType\":\"WITHDRAW\"}";
                if(Double.parseDouble(withdrawStatus)!=-1){
                    status = AccountsService.RESULT_SUCCESS_IS+withdrawStatus+"\",\"operationType\":\"WITHDRAW\"}";
                }
                break;
            case "transact":
                String transactionStatus = account.transactIntraMoney(info.getPayload(), info.getSagaId());
                status = "{\"result\":\"failure\",\"operationType\":\"TRANSACT\"}";
                if(Double.parseDouble(transactionStatus)!=-1){
                    status = AccountsService.RESULT_SUCCESS_IS+transactionStatus+"\",\"operationType\":\"TRANSACT\"}";
                }
                break;
            default:
                logger.error("Invalid Bank A action specified: {}", accountsAction);
            }
        } catch (com.oracle.saga.banka.exception.AccountsException e) {
            logger.error("Unable to create new entry in bank A");
        }catch (oracle.saga.SagaException e){
            logger.error("Unable to create new entry in bank A");
        }

        JsonObject jsonObject;
        try(JsonReader reader = Json.createReader(new java.io.StringReader(status))){
            jsonObject = reader.readObject();
        }
        JsonObjectBuilder jsonObjectBuilder = Json.createObjectBuilder(jsonObject).add("participant", "BankA");
        JsonObject updatedJsonObject = jsonObjectBuilder.build();
        status=updatedJsonObject.toString();

        logger.info("RESPONSE {}", status);
        return status;
    }

    /**
     * parseAccountsAction is used to fetch requested account action from the request JSON.
     */
    private String parseAccountsAction(String payload) {
        Reader inputReader = new StringReader(payload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        String accountsAction = "";

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject currentJsonObj = parser.getObject();
            accountsAction = currentJsonObj.get("operationType").toString()
                    .replaceAll(REG_EXP_REMOVE_QUOTES, "").toLowerCase();
        } catch (OracleJsonException ex) {
            logger.error("Unable to parse payload");
        }
        return accountsAction;
    }
}
