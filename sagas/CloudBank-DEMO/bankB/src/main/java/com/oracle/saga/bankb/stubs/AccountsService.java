/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.bankb.stubs;

import com.oracle.saga.bankb.data.CompensationData;
import com.oracle.saga.bankb.data.CreditResponse;
import com.oracle.saga.bankb.data.ViewBADTO;
import com.oracle.saga.bankb.exception.AccountsException;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.driver.json.tree.OracleJsonObjectImpl;
import oracle.sql.NUMBER;
import oracle.sql.json.OracleJsonException;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonParser;
import org.ehcache.Cache;
import org.ehcache.CacheManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Reader;
import java.io.StringReader;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObjectBuilder;

/**
 * AccountsService is helper class which holds all the functions used by controller.
 */
public class AccountsService {

    private static final String REG_EXP_REMOVE_QUOTES = "(^\")|(\"$)";
    private static final String PENDING = "PENDING";
    private static final String ONGOING = "ONGOING";
    public static final String COMPLETED = "COMPLETED";
    public static final String FAILED = "FAILED";


    public static final String FROM_ACCOUNT_NUMBER = "fromAccountNumber";
    public static final String TO_ACCOUNT_NUMBER = "toAccountNumber";
    public static final String ACCOUNT_TYPE = "account_type";

    public static final String TRANSACTIONTYPE = "transactionType";
    public static final String ACCOUNTNUMBER = "account_number";
    public static final String BALANCEAMOUNT = "balance_amount";
    public static final String UNABLETOPARSEPAYLOAD = "Unable to parse payload";
    public static final String OPERATIONTYPE = "operationType";
    public static final String CREATEDAT = "created_at";
    public static final String AMOUNT = "amount";

    private final Connection connection;
    private static final Logger logger = LoggerFactory.getLogger(AccountsService.class);
    final Cache<String, ArrayList> accountsCompensationCache;

    public AccountsService(Connection conn, CacheManager cacheManager) throws AccountsException {
        accountsCompensationCache = cacheManager.getCache("bankBCompensationData", String.class,
               ArrayList.class);
        if (conn == null) {
            throw new AccountsException("Database connection is invalid.");
        }
        this.connection = conn;
    }

    /**
     * newBankAccount is a helper function to create New Bank Accounts.
     */
    public String newBankAccount(String accountPayload, String sagaId) {

        Reader inputReader = new StringReader(accountPayload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        String accountNumber =null;

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject accountsJsonObj = parser.getObject();
            int statusInsert = insertInBook(accountsJsonObj, sagaId);

            if (statusInsert != -1 ) {
                accountNumber = newInAccountsTable(accountsJsonObj);

                final CompensationData accountsCompensationInfo = new CompensationData();
                accountsCompensationInfo.setSagaId(sagaId);
                accountsCompensationInfo.setUcid(accountsJsonObj.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                accountsCompensationInfo.setOperationType(accountsJsonObj.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                if(accountNumber!=null){
                    accountsCompensationInfo.setAccountNumber(accountNumber);
                }
                ArrayList <CompensationData> temp = new ArrayList<>();
                temp.add(accountsCompensationInfo);
                accountsCompensationCache.put(sagaId, temp);
                updateOperationStatus(sagaId,ONGOING);
                updateAccountNumberInLogs(sagaId, accountNumber);
            } else {
                updateOperationStatus(sagaId,FAILED);
            }

        } catch (OracleJsonException ex) {
            logger.error(UNABLETOPARSEPAYLOAD);
        }
        return accountNumber;
    }

    /**
     * newInAccountsTable is helper function to add new entry in accounts table.
     */
    private String newInAccountsTable(OracleJsonObject account) {
        String newEntryBankAccount = "INSERT INTO bankB(ucid,account_number,account_type,balance_amount) VALUES (?,SEQ_ACCOUNT_NUMBER_BANK_B.NEXTVAL,?,0) RETURNING account_number INTO ?";
        long insertedId=-1;

                try (OraclePreparedStatement stmt1 = (OraclePreparedStatement) connection.prepareStatement(newEntryBankAccount)) {
                    stmt1.setString(1, account.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                    stmt1.setString(2, account.get("accountType").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));

                    stmt1.registerReturnParameter(3, OracleTypes.NUMBER);
                    stmt1.executeUpdate();

                    try (OracleResultSet rs = (OracleResultSet) stmt1.getReturnResultSet()) {
                        if (rs.next()) {
                            insertedId = rs.getLong(1); // Use getLong for NUMBER
                        }
                    }
                } catch (SQLException ex) {
                    logger.error("INSERT IN Bank B ERROR");
                }


                if(insertedId==-1){
                    return null;
                }else{
                    return String.valueOf(insertedId);
                }
    }

    /**
     * newCCAccount is a helper function to create a new Credit Card Account.
     */
    public CreditResponse newCCAccount(String accountPayload, String sagaId) {

        Reader inputReader = new StringReader(accountPayload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        CreditResponse resp= null;

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject accountsJsonObj = parser.getObject();
            int statusInsert = insertInBook(accountsJsonObj, sagaId);

            if (statusInsert != -1 ) {
                resp = newInCCTable(accountsJsonObj);

                final CompensationData restaurantCompensationInfo = new CompensationData();
                restaurantCompensationInfo.setSagaId(sagaId);
                restaurantCompensationInfo.setUcid(accountsJsonObj.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                restaurantCompensationInfo.setOperationType(accountsJsonObj.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                if(resp!=null){
                    restaurantCompensationInfo.setAccountNumber(resp.getAccountNumber());
                }
                ArrayList <CompensationData> temp = new ArrayList<>();
                temp.add(restaurantCompensationInfo);
                accountsCompensationCache.put(sagaId, temp);
                updateOperationStatus(sagaId,ONGOING);
                if (resp != null) {
                    updateAccountNumberInLogs(sagaId, resp.getAccountNumber());
                }
            } else {
                updateOperationStatus(sagaId,FAILED);
            }

        } catch (OracleJsonException ex) {
            logger.error(UNABLETOPARSEPAYLOAD);
        }
        return resp;
    }

    /**
     * newInCCTable is a helper function to add new entry to the accounts table.
     */
    private CreditResponse newInCCTable(OracleJsonObject account) {
        String newEntryBankAccount = "INSERT INTO bankB(ucid,account_number,account_type,balance_amount) VALUES (?,SEQ_CREDIT_CARD_NUMBER_BANK_B.NEXTVAL,?,0) RETURNING account_number INTO ?";
        CreditResponse resp =null;

        try (OraclePreparedStatement stmt1 = (OraclePreparedStatement) connection.prepareStatement(newEntryBankAccount)) {
            stmt1.setString(1, account.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt1.setString(2, account.get("accountType").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));

            stmt1.registerReturnParameter(3, OracleTypes.NUMBER);
            stmt1.executeUpdate();

            try (OracleResultSet rs = (OracleResultSet) stmt1.getReturnResultSet()) {
                if (rs.next()) {
                    resp = new CreditResponse();
                    resp.setAccountNumber(String.valueOf(rs.getLong(1)));
                    resp.setCreditLimit("0");
                }
            }
        } catch (SQLException ex) {
            logger.error("INSERT IN Bank B ERROR");
        }

        return resp;
    }

    /**
     * updateCreditLimit is a helper function to update credit balance in accounts table.
     */
    public boolean updateCreditLimit(String accountPayload, String sagaId) {

        Reader inputReader = new StringReader(accountPayload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        boolean resp=Boolean.FALSE;

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject accountsJsonObj = parser.getObject();
            int statusInsert = insertInBook(accountsJsonObj, sagaId);

            if (statusInsert != -1 ) {
                resp = updateInCCTable(accountsJsonObj);

                if(!Boolean.FALSE.equals(resp)){
                    final CompensationData restaurantCompensationInfo = new CompensationData();
                    restaurantCompensationInfo.setSagaId(sagaId);
                    restaurantCompensationInfo.setUcid(accountsJsonObj.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                    restaurantCompensationInfo.setOperationType(accountsJsonObj.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                    ArrayList <CompensationData> temp = new ArrayList<>();
                    temp.add(restaurantCompensationInfo);
                    accountsCompensationCache.put(sagaId, temp);
                }
                updateOperationStatus(sagaId,ONGOING);
            } else {
                updateOperationStatus(sagaId,FAILED);
            }

        } catch (OracleJsonException ex) {
            logger.error(UNABLETOPARSEPAYLOAD);
        }
        return resp;
    }

    /**
     * updateInCCTable is a helper function to update the credit limit in respective table.
     */
    private boolean updateInCCTable(OracleJsonObject account) {
        String newEntryBankAccount = "UPDATE bankB SET balance_amount = balance_amount + ? where account_number = ?";
        int insertRslt = 0;

        try (PreparedStatement stmt1 = connection.prepareStatement(newEntryBankAccount)) {

            stmt1.setDouble(1, Double.parseDouble(account.get("balanceAmount").toString().replaceAll(REG_EXP_REMOVE_QUOTES, "")));
            stmt1.setString(2, account.get("accountNumber").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));

            insertRslt = stmt1.executeUpdate();

            if(insertRslt!=1){
                insertRslt=-1;
            }
        } catch (SQLException ex) {
            logger.error("INSERT IN ACCOUNTS ERROR");
        }

        return insertRslt>0;
    }

    /**
     * depositMoney is a helper function to deposit funds in respective account.
     */
    public String depositMoney(String accountPayload, String sagaId) {

        Reader inputReader = new StringReader(accountPayload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        double balanceAmount=-1.0;

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject accountsJsonObj = parser.getObject();
            int statusInsert = insertInBookTransfer(accountsJsonObj, sagaId);

            if (statusInsert != -1 ) {
                balanceAmount = transactMoney(sagaId,accountsJsonObj);

                if(balanceAmount!=-1.0){
                    final CompensationData accountsCompensationInfo = new CompensationData();
                    accountsCompensationInfo.setSagaId(sagaId);
                    accountsCompensationInfo.setUcid(accountsJsonObj.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                    accountsCompensationInfo.setOperationType(accountsJsonObj.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                    ArrayList <CompensationData> temp = new ArrayList<>();
                    temp.add(accountsCompensationInfo);
                    accountsCompensationCache.put(sagaId, temp);
                }else{
                    updateOperationStatus(sagaId,FAILED,accountsJsonObj.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                }
                updateOperationStatus(sagaId,ONGOING,accountsJsonObj.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            }

        } catch (OracleJsonException ex) {
            logger.error(UNABLETOPARSEPAYLOAD);
        }
        return String.valueOf(balanceAmount);
    }

    /**
     * withdrawMoney is a helper function to withdraw funds from respective account.
     */
    public String withdrawMoney(String accountPayload, String sagaId) {

        Reader inputReader = new StringReader(accountPayload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        double balanceAmount=-1.0;

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject accountsJsonObj = parser.getObject();
            int statusInsert = insertInBookTransfer(accountsJsonObj, sagaId);

            if (statusInsert != -1 ) {
                if(validateUserWithdrawing(accountsJsonObj)){

                    balanceAmount = transactMoney(sagaId,accountsJsonObj);

                    if(balanceAmount!=-1.0){
                        final CompensationData accountsCompensationInfo = new CompensationData();
                        accountsCompensationInfo.setSagaId(sagaId);
                        accountsCompensationInfo.setUcid(accountsJsonObj.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                        accountsCompensationInfo.setOperationType(accountsJsonObj.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                        ArrayList <CompensationData> temp = new ArrayList<>();
                        temp.add(accountsCompensationInfo);
                        accountsCompensationCache.put(sagaId, temp);
                    }else{
                        updateOperationStatus(sagaId,FAILED,accountsJsonObj.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                    }

                }else{
                    updateOperationStatus(sagaId,FAILED,accountsJsonObj.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                }
                updateOperationStatus(sagaId,ONGOING,accountsJsonObj.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            }

        } catch (OracleJsonException ex) {
            logger.error(UNABLETOPARSEPAYLOAD);
        }
        return String.valueOf(balanceAmount);
    }

    /**
     * transactIntraMoney performs transactions in the same bank.
     */
    public String transactIntraMoney(String accountPayload, String sagaId) {

        Reader inputReader = new StringReader(accountPayload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();
        double balanceAmountWithdraw=-1.0;
        double balanceAmountDeposit;

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject accountsJsonObjOG = parser.getObject();

            OracleJsonObject accountsJsonObjWithdraw = new OracleJsonObjectImpl(accountsJsonObjOG);
            accountsJsonObjWithdraw.put(OPERATIONTYPE,"WITHDRAW");
            accountsJsonObjWithdraw.put(TRANSACTIONTYPE,"DEBIT");
            OracleJsonObject accountsJsonObjDeposit = new OracleJsonObjectImpl(accountsJsonObjOG);
            accountsJsonObjDeposit.put(OPERATIONTYPE,"DEPOSIT");
            accountsJsonObjDeposit.put(TRANSACTIONTYPE,"CREDIT");

            int statusInsert1 = insertInBookTransfer(accountsJsonObjWithdraw, sagaId);
            int statusInsert2 = insertInBookTransfer(accountsJsonObjDeposit, sagaId);

            if (statusInsert1 != -1  && statusInsert2 != -1) {
                balanceAmountDeposit = transactMoney(sagaId,accountsJsonObjDeposit);

                if(balanceAmountDeposit!=-1.0){
                    updateOperationStatus(sagaId,ONGOING,accountsJsonObjDeposit.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                }else{
                    updateOperationStatus(sagaId,FAILED,accountsJsonObjDeposit.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                }

                if(validateUserWithdrawing(accountsJsonObjWithdraw)){
                    balanceAmountWithdraw = transactMoney(sagaId,accountsJsonObjWithdraw);
                    if(balanceAmountWithdraw!=-1.0){
                        updateOperationStatus(sagaId,ONGOING,accountsJsonObjWithdraw.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                    }else{
                        updateOperationStatus(sagaId,FAILED,accountsJsonObjWithdraw.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                    }
                }else{
                    updateOperationStatus(sagaId,FAILED,accountsJsonObjWithdraw.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                }

                if(balanceAmountDeposit == -1.0 || balanceAmountWithdraw == -1.0){
                    return String.valueOf(Math.min(balanceAmountDeposit, balanceAmountWithdraw));
                }

                final CompensationData accountsCompensationInfo = new CompensationData();
                accountsCompensationInfo.setSagaId(sagaId);
                accountsCompensationInfo.setUcid(accountsJsonObjOG.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                accountsCompensationInfo.setOperationType(accountsJsonObjOG.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                ArrayList <CompensationData> temp = new ArrayList<>();
                temp.add(accountsCompensationInfo);
                accountsCompensationCache.put(sagaId, temp);

                return String.valueOf(balanceAmountWithdraw);
            }else{
                if(statusInsert1==-1 && statusInsert2 !=-1){
                    updateOperationStatus(sagaId,FAILED,accountsJsonObjDeposit.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                }
                if(statusInsert2==-1 && statusInsert1!=-1){
                    updateOperationStatus(sagaId,FAILED,accountsJsonObjWithdraw.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                }
            }


        } catch (OracleJsonException ex) {
            logger.error(UNABLETOPARSEPAYLOAD);
        }

        return String.valueOf(balanceAmountWithdraw);
    }

    /**
     * validateUserWithdrawing validates the user ownership over withdrawing account.
     */
    private boolean validateUserWithdrawing(OracleJsonObject accountsJsonObj) {

        String selectCC = "SELECT COUNT(*) from bankB where ucid = ? and account_number = ?";

        int count=-1;
        try (OraclePreparedStatement stmt = (OraclePreparedStatement) connection.prepareStatement(selectCC)) {
            stmt.setString(1, accountsJsonObj.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(2, accountsJsonObj.get(FROM_ACCOUNT_NUMBER).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));

            stmt.executeUpdate();

            try (ResultSet rs = stmt.getReturnResultSet()) {
                if (rs.next()) {
                    count= rs.getInt(1);
                }
            }

        } catch (OracleJsonException | SQLException ex) {
            logger.error("Validate Bank B error");
        }

        return count==1;
    }

    /**
     * viewAllAccounts executes queries to fetch all accounts in above function.
     */
    public static String viewAllAccounts(Connection connection, ViewBADTO payload, String type){
        String selectBAC = "SELECT account_number, account_type, balance_amount, created_at from bankB where ucid = ? and account_type = 'CHECKING'";
        String selectBAS = "SELECT account_number, account_type, balance_amount, created_at from bankB where ucid = ? and account_type = 'SAVING'";
        String selectCC = "SELECT account_number, account_type, balance_amount, created_at from bankB where ucid = ? and account_type = 'CREDIT_CARD'";
        JsonObjectBuilder jsonObjectBuilderP = Json.createObjectBuilder();

        try {
            switch (type) {
                case "ALL":
                case "CHECKING":
                    try (PreparedStatement stmt1 = connection.prepareStatement(selectBAC)) {
                        JsonArrayBuilder jsonArrayBuilder1 = Json.createArrayBuilder();
                        stmt1.setString(1, payload.getUcid());

                        stmt1.executeUpdate();
                        try (ResultSet rs = stmt1.getResultSet()) {
                            while (rs.next()) {
                                JsonObjectBuilder jsonObjectBuilder = Json.createObjectBuilder();
                                jsonObjectBuilder.add(ACCOUNTNUMBER, rs.getString(ACCOUNTNUMBER));
                                jsonObjectBuilder.add(ACCOUNT_TYPE, rs.getString(ACCOUNT_TYPE));
                                jsonObjectBuilder.add(BALANCEAMOUNT, rs.getDouble(BALANCEAMOUNT));
                                jsonObjectBuilder.add(CREATEDAT, rs.getTimestamp(CREATEDAT).toString());
                                jsonArrayBuilder1.add(jsonObjectBuilder.build());
                            }
                        }
                        jsonObjectBuilderP.add("CHECKING", jsonArrayBuilder1.build());
                    }

                    if (!type.equals("ALL")) break;
                    // fallthrough

                case "SAVING":
                    try (PreparedStatement stmt2 = connection.prepareStatement(selectBAS)) {
                        JsonArrayBuilder jsonArrayBuilder2 = Json.createArrayBuilder();
                        stmt2.setString(1, payload.getUcid());

                        stmt2.executeUpdate();
                        try (ResultSet rs = stmt2.getResultSet()) {
                            while (rs.next()) {
                                JsonObjectBuilder jsonObjectBuilder = Json.createObjectBuilder();
                                jsonObjectBuilder.add(ACCOUNTNUMBER, rs.getString(ACCOUNTNUMBER));
                                jsonObjectBuilder.add(ACCOUNT_TYPE, rs.getString(ACCOUNT_TYPE));
                                jsonObjectBuilder.add(BALANCEAMOUNT, rs.getDouble(BALANCEAMOUNT));
                                jsonObjectBuilder.add(CREATEDAT, rs.getTimestamp(CREATEDAT).toString());
                                jsonArrayBuilder2.add(jsonObjectBuilder.build());
                            }
                        }
                        jsonObjectBuilderP.add("SAVING", jsonArrayBuilder2.build());
                    }
                    if (!type.equals("ALL")) break;
                    // fallthrough

                case "CREDIT_CARD":
                    try (PreparedStatement stmt3 = connection.prepareStatement(selectCC)) {
                        JsonArrayBuilder jsonArrayBuilder3 = Json.createArrayBuilder();

                        stmt3.setString(1, payload.getUcid());

                        stmt3.executeUpdate();
                        try (ResultSet rs = stmt3.getResultSet()) {
                            while (rs.next()) {
                                JsonObjectBuilder jsonObjectBuilder = Json.createObjectBuilder();
                                jsonObjectBuilder.add(ACCOUNTNUMBER, rs.getString(ACCOUNTNUMBER));
                                jsonObjectBuilder.add(ACCOUNT_TYPE, rs.getString(ACCOUNT_TYPE));
                                jsonObjectBuilder.add(BALANCEAMOUNT, rs.getDouble(BALANCEAMOUNT));
                                jsonObjectBuilder.add(CREATEDAT, rs.getTimestamp(CREATEDAT).toString());
                                jsonArrayBuilder3.add(jsonObjectBuilder.build());
                            }
                        }

                        jsonObjectBuilderP.add("CREDIT_CARD", jsonArrayBuilder3.build());
                    }
                    if (!type.equals("ALL")) break;
                    // fallthrough
                default:
                    break;

            }
        }   catch (OracleJsonException | SQLException ex) {
            logger.error("FETCH CC error");
        }

        return jsonObjectBuilderP.build().toString();
    }

    /**
     * transactMoney executes queries to perform balance updates for deposit and withdraw functionality.
     */
    public double transactMoney(String sagaId,OracleJsonObject accountsJsonObj){
        String withdraw = "UPDATE bankB set balance_amount = balance_amount - ? where account_number = ?";
        String deposit = "UPDATE bankB set balance_amount = balance_amount + ? where account_number = ?";
        int rslt;
        double finalBalance = -1.0;
        String finalQuery;
        Boolean isCredit = Boolean.FALSE;
        if(accountsJsonObj.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, "").equals("CREDIT")){
            finalQuery = deposit;
            isCredit = Boolean.TRUE;
        }else{
            finalQuery = withdraw;
        }

        try (OraclePreparedStatement stmt = (OraclePreparedStatement) connection.prepareStatement(finalQuery)) {
            if(isCredit.equals(Boolean.TRUE)){
                stmt.setDouble(1, Double.parseDouble(accountsJsonObj.get(AMOUNT).toString().replaceAll(REG_EXP_REMOVE_QUOTES, "")));
                stmt.setNUMBER(2, NUMBER.textToPrecisionNumber(accountsJsonObj.get(TO_ACCOUNT_NUMBER).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""),true,3,false,3,null));
            }else{
                stmt.setDouble(1, Double.parseDouble(accountsJsonObj.get(AMOUNT).toString().replaceAll(REG_EXP_REMOVE_QUOTES, "")));
                stmt.setNUMBER(2, NUMBER.textToPrecisionNumber(accountsJsonObj.get(FROM_ACCOUNT_NUMBER).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""),true,3,false,3,null));
            }

            rslt = stmt.executeUpdate();

            if(rslt==1){

                finalBalance = fetchBalance(isCredit, accountsJsonObj);

            }


        } catch (OracleJsonException | SQLException ex) {
            logger.error("UPDATE STATUS from ACCOUNTS_BOOK error");
            updateOperationStatus(sagaId, AccountsService.FAILED);
        }
        return finalBalance;
    }

    private double fetchBalance(Boolean isCredit, OracleJsonObject accountsJsonObj) {
        double finalBalance =-1.0;
        String selectBalance = "SELECT balance_amount from bankB where account_number = ?";
        try (OraclePreparedStatement stmt1 = (OraclePreparedStatement) connection.prepareStatement(selectBalance)) {
            if(isCredit.equals(Boolean.TRUE)){
                stmt1.setNUMBER(1, NUMBER.textToPrecisionNumber(accountsJsonObj.get(TO_ACCOUNT_NUMBER).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""),true,3,false,3,null));
            }else{
                stmt1.setNUMBER(1, NUMBER.textToPrecisionNumber(accountsJsonObj.get(FROM_ACCOUNT_NUMBER).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""),true,3,false,3,null));
            }

            stmt1.executeUpdate();

            try (ResultSet rs = stmt1.getReturnResultSet()) {
                if (rs.next()) {
                    finalBalance = rs.getDouble(BALANCEAMOUNT);
                }
            }

        } catch (OracleJsonException | SQLException ex) {
            logger.error("FETCH Balance Amount error");
        }
        return finalBalance;
    }

    /**
     * updateOperationStatus updates the operation status in accounts_book table.
     */
    public void updateOperationStatus(String sagaId, String state){
        String updateOperationStateBooking = "UPDATE bankB_book set operation_status = ? where SAGA_ID = ?";
        try (PreparedStatement stmt = connection.prepareStatement(updateOperationStateBooking)) {
            stmt.setString(1, state);
            stmt.setString(2, sagaId);

            stmt.executeUpdate();
        } catch (OracleJsonException | SQLException ex) {
            logger.error("UPDATE STATUS from Bank B error");
        }
    }

    /**
     * updateAccountNumberInLogs updates account number in the accounts_book table.
     */
    public void updateAccountNumberInLogs(String sagaId, String accountNumber){
        String updateOperationStateBooking = "UPDATE bankB_book set account_number = ? where SAGA_ID = ?";

        try (PreparedStatement stmt = connection.prepareStatement(updateOperationStateBooking)) {
            stmt.setString(1, accountNumber);
            stmt.setString(2, sagaId);

            stmt.executeUpdate();
        } catch (OracleJsonException | SQLException ex) {
            logger.error("UPDATE Account number in Bank B error");
        }
    }

    /**
     * updateOperationStatus updates the operation status in accounts_book table for a particular transaction type (CREDIT OR DEBIT).
     */
    public void updateOperationStatus(String sagaId, String state, String txnType){
        String updateOperationStateBooking = "UPDATE bankB_book set operation_status = ? where SAGA_ID = ? and transactionType = ?";
        try (PreparedStatement stmt = connection.prepareStatement(updateOperationStateBooking)) {
            stmt.setString(1, state);
            stmt.setString(2, sagaId);
            stmt.setString(3, txnType);

            stmt.executeUpdate();
        } catch (OracleJsonException | SQLException ex) {
            logger.error("UPDATE STATUS from Bank B error");
        }
    }

    /**
     * insertInBook inserts logs in the accounts_book table.
     */
    private int insertInBook(OracleJsonObject account, String sagaId) {

        String insertCustomerInfo = "INSERT INTO bankB_book (saga_id, ucid, operationType, transactionType, transaction_amount, account_number,operation_status) VALUES (?,?,?,?,?,?,?)";
        int insertRslt = 0;
        try (PreparedStatement stmt = connection.prepareStatement(insertCustomerInfo)) {
            stmt.setString(1,sagaId);
            stmt.setString(2,account.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(3,account.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(4,account.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            if(!account.get("transactionAmount").toString().replaceAll(REG_EXP_REMOVE_QUOTES, "").equals("null")){
                stmt.setDouble(5,Double.parseDouble(account.get("transactionAmount").toString().replaceAll(REG_EXP_REMOVE_QUOTES, "")));
            }else{
                stmt.setDouble(5,Double.parseDouble("0.00"));
            }

            stmt.setString(6,account.get("accountNumber").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(7, PENDING);

            insertRslt = stmt.executeUpdate();

            if (insertRslt != 1) {
                insertRslt = -1;
            }

        } catch (SQLException ex) {
            logger.error("Insert accounts error");
        }

        return insertRslt;
    }

    /**
     * insertInBookTransfer inserts logs in the accounts_book table for money transfer services.
     */
    private int insertInBookTransfer(OracleJsonObject account, String sagaId) {

        String insertCustomerInfo = "INSERT INTO bankB_book (saga_id, ucid, operationType, transactionType, transaction_amount, account_number,operation_status) VALUES (?,?,?,?,?,?,?)";
        int insertRslt = 0;
        try (PreparedStatement stmt = connection.prepareStatement(insertCustomerInfo)) {
            stmt.setString(1,sagaId);
            stmt.setString(2,account.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(3,account.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(4,account.get(TRANSACTIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            if(!account.get(AMOUNT).toString().replaceAll(REG_EXP_REMOVE_QUOTES, "").equals("null")){
                stmt.setDouble(5,Double.parseDouble(account.get(AMOUNT).toString().replaceAll(REG_EXP_REMOVE_QUOTES, "")));
            }else{
                stmt.setDouble(5,Double.parseDouble("0.00"));
            }
            if(account.get(OPERATIONTYPE).toString().replaceAll(REG_EXP_REMOVE_QUOTES, "").equalsIgnoreCase("deposit")){
                stmt.setString(6,account.get(TO_ACCOUNT_NUMBER).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            }else{
                stmt.setString(6,account.get(FROM_ACCOUNT_NUMBER).toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            }
            stmt.setString(7, PENDING);

            insertRslt = stmt.executeUpdate();

            if (insertRslt != 1) {
                insertRslt = -1;
            }

        } catch (SQLException ex) {
            logger.error("Insert accounts error");
        }

        return insertRslt;
    }

    /**
     * deleteAccount deletes account from the accounts table.
     */
    public boolean deleteAccount(CompensationData account) {
        String deleteAccount = "DELETE FROM bankB where ACCOUNT_NUMBER = ?";
        int rslt = 0;
        try (PreparedStatement stmt = connection.prepareStatement(deleteAccount)) {
            stmt.setString(1, account.getAccountNumber());

            rslt = stmt.executeUpdate();
        } catch (OracleJsonException | SQLException ex) {
            logger.error("UNABLE TO DELETE ACCOUNT FROM Bank B");
        }
        return rslt > 0;
    }

}
