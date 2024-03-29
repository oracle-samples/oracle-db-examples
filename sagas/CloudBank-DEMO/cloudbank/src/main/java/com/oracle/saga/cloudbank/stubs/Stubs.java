/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.cloudbank.stubs;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oracle.saga.cloudbank.data.*;
import jakarta.ws.rs.core.Response;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;
import oracle.sql.json.OracleJsonException;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonParser;
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
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import jakarta.json.Json;

/**
 * Stubs is helper class which holds all the functions used by the respective controller.
 */
public class Stubs {
    private Stubs() {
    }

    private static final Logger logger = LoggerFactory.getLogger(Stubs.class);

    public static final String URL_VALIDATE_CUSTOMER_IN_CREDIT_SCORE_DB = "<CREDITSCORE_URL:PORT>/creditscore/validateCreditScore";
    public static final String URL_VIEW_CREDIT_SCORE_IN_CREDIT_SCORE_DB = "<CREDITSCORE_URL:PORT>/creditscore/viewCreditScore";
    public static final String URL_VIEW_ALL_ACCOUNTS_BANK_A = "<BANKA_URL:PORT>/bankA/viewAccounts";
    public static final String URL_VERIFY_ACCOUNT_BANK_A = "<BANKA_URL:PORT>/bankA/isInBank";
    public static final String URL_VIEW_ALL_ACCOUNTS_BANK_B = "<BANKB_URL:PORT>/bankB/viewAccounts";

    public static final String OPERATIONTYPE = "operationType";
    public static final String DEPOSIT = "DEPOSIT";
    public static final String TRANSACTIONTYPE = "transactionType";

    public static final String CACHE_NAME = "cloudBankSaga";
    public static final String HEADER_JSON = "application/json";
    public static final String CONTENT_TYPE = "Content-Type";
    public static final String ACCEPTED_STATUS = "Accepted";
    public static final String RESPONSE_REASON = "reason";
    public static final String RESPONSE_IS = "The response: {}";
    public static final String FETCH_OSSN_ERROR = "FETCH OSSN ERROR";
    public static final String BANK_A = "BankA";
    public static final String STATUS_OF = "Status of {} returned.";
    public static final String NEW_ACCOUNT = "NEW_ACCOUNT";
    public static final String PENDING = "PENDING";
    public static final String BANK_B = "BankB";
    public static final String ONGOING = "ONGOING";
    public static final String FAILED = "FAILED";
    public static final String NEW_CREDIT_CARD = "NEW_CREDIT_CARD";
    public static final String TRANSFER = "TRANSFER";
    public static final String WITHDRAW = "WITHDRAW";
    public static final String REPLACE_STRING = "(^\")|(\"$)";
    public static final String COMMITTING_SAGA = "Committing Saga [{}]";
    public static final String COMPLETED = "COMPLETED";
    public static final String ROLLBACK_INTENTIONAL = "Intentionally Causing a Rollback for Saga [{}]";
    public static final String FINALIZE_ERROR = "Unable to finalize";





    /**
     *createNewCustomer inserts new entries into cloudbank_Customer table.
     */
    public static String createNewCustomer(Connection connection, NewCustomerDTO payload) {

        var insertCustomerInfo = "INSERT INTO cloudbank_customer (customer_id, password, full_name, address, phone, email,ossn, bank) VALUES (SEQ_CLOUDBANK_CUSTOMER_ID.NEXTVAL,?,?,?,?,?,?,?) RETURNING customer_id into ?";

        String customerId=null;
        try (OraclePreparedStatement stmt = (OraclePreparedStatement) connection.prepareStatement(insertCustomerInfo)) {
            stmt.setString(1, payload.getPassword());
            stmt.setString(2, payload.getFullName());
            stmt.setString(3, payload.getAddress());
            stmt.setString(4, payload.getPhone());
            stmt.setString(5, payload.getEmail());
            stmt.setString(6, payload.getOssn());
            stmt.setString(7, payload.getBank());

            stmt.registerReturnParameter(8, OracleTypes.VARCHAR);

            stmt.executeUpdate();

            try (OracleResultSet rs = (OracleResultSet) stmt.getReturnResultSet()) {
                if (rs.next()) {
                    customerId = rs.getString(1);
                }
            }

        } catch (SQLException ex) {
            logger.error("Insert customer error");
        }

        return customerId;

    }

    /**
     * login helps verify customer as per their login details.
     */
    public static LoginReplyDTO login(Connection connection, LoginDTO payload) {

        var query = "SELECT customer_id, full_name, address, phone, email, ossn, bank from cloudbank_customer where customer_id = ? and password = ?";
        LoginReplyDTO reply = null;

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setString(1, payload.getId());
            stmt.setString(2, payload.getPwd());

            stmt.executeUpdate();

            try (var rs = stmt.getResultSet()) {
                if (rs.next()) {
                    reply=new LoginReplyDTO();

                    reply.setUcid(rs.getString("customer_id"));
                    reply.setFullName(rs.getString("full_name"));
                    reply.setAddress(rs.getString("address"));
                    reply.setPhone(rs.getString("phone"));
                    reply.setEmail(rs.getString("email"));
                    reply.setOssn(rs.getString("ossn"));
                    reply.setBank(rs.getString("bank"));
                }
            }
        } catch (SQLException ex) {
            logger.error("Login error");
        }

        return reply;
    }

    /**
     * verifyUserForTransaction helps verify customer as per their login details.
     */
    public static boolean verifyUserForTransaction(Connection connection,AccountTransferDTO payload) {

        var query = "SELECT count(*) from cloudbank_customer where customer_id = ? and password = ?";
        Boolean validateStatus =Boolean.FALSE;

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setString(1, payload.getUcid());
            stmt.setString(2, payload.getPassword());

            stmt.executeUpdate();

            var rs = stmt.getResultSet();
            if (rs.next()) {
                var count = rs.getInt(1);
                if(count==1){
                    validateStatus=Boolean.TRUE;
                }
            }
        } catch (SQLException ex) {
            logger.error("Validation Error");
        }

        return validateStatus;

    }

    /**
     *  getNotifications is a helper function for notification functionality.
     */
    public static String getNotifications(Connection connection){

        var getNotificationQuery = "UPDATE cloudbank_book SET read = 'TRUE' WHERE read = 'FALSE' and operation_status != 'PENDING' and operation_status != 'ONGOING' RETURNING saga_id,ucid,operationType,operation_status into ?,?,?,?";
        NotificationDTO resp ;
        var jsonArrayBuilder = Json.createArrayBuilder();

        try (OraclePreparedStatement stmt1 = (OraclePreparedStatement) connection.prepareStatement(getNotificationQuery)) {

            stmt1.registerReturnParameter(1, OracleTypes.VARCHAR);
            stmt1.registerReturnParameter(2, OracleTypes.VARCHAR);
            stmt1.registerReturnParameter(3, OracleTypes.VARCHAR);
            stmt1.registerReturnParameter(4, OracleTypes.VARCHAR);

            stmt1.executeUpdate();

            try (OracleResultSet rs = (OracleResultSet) stmt1.getReturnResultSet()) {
                while (rs.next()) {
                    resp = new NotificationDTO();
                    resp.setSagaId(rs.getString(1));
                    resp.setUcid(rs.getString(2));
                    resp.setOperationType(rs.getString(3));
                    resp.setOperationStatus(rs.getString(4));

                    jsonArrayBuilder.add(resp.toString());
                }
            }
        } catch (SQLException ex) {
            logger.error("NOTIFICATION ERROR");
        }

        return jsonArrayBuilder.build().toString();

    }

    /**
     * fetchOssnByUCID fetches OSSN based on UCID of the customer
     */
    public static String fetchOssnByUCID(Connection connection,Accounts payload) {

        var selectCc = "SELECT ossn from cloudbank_customer where customer_id = ?";
        String ossn =null;
        try (OraclePreparedStatement stmt = (OraclePreparedStatement) connection.prepareStatement(selectCc)) {
            stmt.setString(1, payload.getUcid());

            stmt.executeUpdate();

            try (var rs = stmt.getReturnResultSet()) {
                if (rs.next()) {
                    ossn = rs.getString("ossn");
                }
            }

        } catch (OracleJsonException | SQLException ex) {
            logger.error("FETCH OSSN error");
        }
        return ossn;
    }

    /**
     * setBalanceNewCC decides limit for new credit card as per their credit score.
     */
    public static String setBalanceNewCC(String creditScoreResponse) {

        Reader inputReader = new StringReader(creditScoreResponse);
        var factory = new OracleJsonFactory();
        OracleJsonParser parser = null;
        try {
            parser = factory.createJsonTextParser(inputReader);
            parser.next();
            OracleJsonObject currentJsonObj = parser.getObject();
            var creditScoreStr = currentJsonObj.get("credit_score").toString().replaceAll(REPLACE_STRING,"");
            int creditscore = Integer.parseInt(creditScoreStr);

            if (creditscore <= 650) {
                return null;
            } else if (creditscore <= 720) {
                return "2000.00";
            } else if (creditscore <= 780) {
                return "5000.00";
            } else if (creditscore <= 820) {
                return "10000.00";
            } else {
                return "20000.00";
            }
        } catch (NumberFormatException e) {
            logger.error("Error parsing credit score");
        } finally {
            if (parser != null) {
                parser.close();
            }
        }
        return null;
    }

    /**
     * getBankBasedOnUCID fetches bank for appropriate account request endpoints.
     */
    public static String getBankBasedOnUCID(Connection connection, String ucid){
        if(ucid==null){
            return null;
        }
        var bankQ = "SELECT bank from cloudbank_customer where customer_id = ?";
        String bank =null;
        try (OraclePreparedStatement stmt = (OraclePreparedStatement) connection.prepareStatement(bankQ)) {
            stmt.setString(1, ucid);

            stmt.executeUpdate();

            try (var rs = stmt.getReturnResultSet()) {
                if (rs.next()) {
                    bank = rs.getString("bank");
                }
            }

        } catch (OracleJsonException | SQLException ex) {
            logger.error("FETCH OSSN error");
        }
        return bank;
    }

    /**
     *bankCompare is a helper function for getBankBasedOnUCID.
     */
    public static Boolean bankCompare(String bank, String toAccountNumber) {

        var client1 = HttpClient.newHttpClient();
        HttpRequest request1 ;

        var obj = new ObjectMapper();
        var rpayload = obj.createObjectNode();
        rpayload.put("accountnumber", toAccountNumber);
        HttpResponse<String> apiResp1 =null;

        try {
            request1 = HttpRequest.newBuilder()
                    .uri(new URI(Stubs.URL_VERIFY_ACCOUNT_BANK_A))
                    .header(CONTENT_TYPE, HEADER_JSON)
                    .POST(HttpRequest.BodyPublishers.ofString(rpayload.toString()))
                    .build();
            apiResp1 = client1.send(request1, HttpResponse.BodyHandlers.ofString());
        }catch (URISyntaxException | IOException | InterruptedException e){
            logger.error("bank compare error");
        }
        String bankTo;
        if(apiResp1!=null){
            if(apiResp1.statusCode() == Response.Status.ACCEPTED.getStatusCode()){
                bankTo = BANK_A;
            }else{
                bankTo = BANK_B;
            }
        }else{
            bankTo = BANK_B;
        }

        return bank.equalsIgnoreCase(bankTo);

    }

}
