/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.creditscore.stubs;

import com.oracle.saga.creditscore.data.CreditScoreDTO;
import com.oracle.saga.creditscore.exception.CreditScoreException;
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
import java.sql.SQLException;
import java.util.ArrayList;

public class CreditScoreService {

    private static final String REG_EXP_REMOVE_QUOTES = "(^\")|(\"$)";
    public static final String SUCCESS = "Credit Score enquiry updated successfully.";
    public static final String FAILURE = "Failed to update credit score enquiry";


    private final Connection connection;
    private static final Logger logger = LoggerFactory.getLogger(CreditScoreService.class);
    final Cache<String, ArrayList> creditScoreCompensationCache;

    public CreditScoreService(Connection conn, CacheManager cacheManager) throws CreditScoreException {
        creditScoreCompensationCache = cacheManager.getCache("creditScoreCompensationData", String.class,
                ArrayList.class);
        if (conn == null) {
            throw new CreditScoreException("Database connection is invalid.");
        }
        this.connection = conn;
    }

    /**
     * viewCreditScore fetches credit_score based on OSSN.
     */
    public static String viewCreditScore(Connection connection, CreditScoreDTO payload) {

        var findcreditScoreQuery = "SELECT credit_score FROM credit_score_db WHERE ossn = ?";
        int creditScore=-1;

        try (PreparedStatement findcreditScoreStmt = connection.prepareStatement(findcreditScoreQuery)){
            findcreditScoreStmt.setString(1, payload.getOssn());
            findcreditScoreStmt.execute();

            try (var resultSet = findcreditScoreStmt.getResultSet()) {
                if (resultSet.next()) {
                    creditScore = resultSet.getInt("credit_score");
                }else{
                    return null;
                }
            }

        }catch (java.sql.SQLException e) {
            logger.error("Failed to fetch credit score");
        }

        if(creditScore==-1){
            return null;
        }else{
            return ""+creditScore;
        }

    }

    /**
     * viewCreditScore fetches credit_Score
     */
    public int viewCreditScore(String creditScorePayload){
        
        int creditScore =-1;

        Reader inputReader = new StringReader(creditScorePayload);
        var jsonFactory = new OracleJsonFactory();

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject creditScoreJsonObj = parser.getObject();
            
            creditScore = findcreditScore(creditScoreJsonObj);

        } catch (OracleJsonException ex) {
            logger.error("Unable to parse payload", ex);
        }

        return creditScore;
    }

    /**
     * findcreditScore fetches credit_Score for customer based on ossn.
     */
    private int findcreditScore(OracleJsonObject creditScoreObject){

        var ossn = creditScoreObject.get("ossn").toString().replaceAll(REG_EXP_REMOVE_QUOTES, "");
        var findcreditScoreQuery = "SELECT credit_score FROM credit_score_db WHERE ossn=?";
        int creditScore=-1;

        try (PreparedStatement findcreditScoreStmt = connection.prepareStatement(findcreditScoreQuery)) {
            findcreditScoreStmt.setString(1, ossn);
            findcreditScoreStmt.execute();

            try (var resultSet = findcreditScoreStmt.getResultSet()) {
                if (resultSet.next()) {
                    creditScore = resultSet.getInt("credit_score");
                }else{
                    return -1;
                }
            }

        }catch (java.sql.SQLException e) {
            logger.error("Failed to fetch credit score");
        }

        return creditScore;
    }

    /**
     * updateBookNewEnquiry inserts new entry in credit_Score_book.
     */
    public void updateBookNewEnquiry(String creditScorePayload, String sagaId){

        var jsonFactory = new OracleJsonFactory();
        Reader inputReader = new StringReader(creditScorePayload);

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject creditScoreObject = parser.getObject();
            var insertcreditBook = "INSERT INTO credit_score_book(saga_id, operationType, ossn, ucid, operation_status) values (?,'CREDIT_CHECK',?,?,'ONGOING')";
            try (PreparedStatement insertcreditBookStatement = connection.prepareStatement(insertcreditBook)) {
                insertcreditBookStatement.setString(1,sagaId);
                insertcreditBookStatement.setString(2,creditScoreObject.get("ossn").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                insertcreditBookStatement.setString(3,creditScoreObject.get("ucid").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
                insertcreditBookStatement.executeUpdate();
                logger.debug(SUCCESS);
            }
        } catch (SQLException ex) {
            logger.error("Unable to parse payload");
        }
    }

    /**
     * updateBookPreCommit updates credit_Score_book before committing saga.
     */
    public boolean updateBookPreCommit(String sagaId){

        var updateRslt = 1;
        var updatecreditScoreBook = "UPDATE credit_score_book SET operation_status = 'COMPLETED' where saga_id = ?";
        try (PreparedStatement updatecreditScoreBookStmt = connection.prepareStatement(updatecreditScoreBook)) {
            updatecreditScoreBookStmt.setString(1,sagaId);
            updatecreditScoreBookStmt.executeUpdate();
            logger.debug(SUCCESS);
        }catch (SQLException e) {
            logger.error(FAILURE);
            updateRslt=-1;
        }
        return updateRslt > 0;
    }

    /**
     *updateBookRollback updates credit_score_book
     */
    public boolean updateBookRollback(String sagaId){

        var updateRslt = 1;
        var updatecreditScoreBook = "UPDATE credit_score_book SET operation_status = 'FAILED' where saga_id = ?";
        try (PreparedStatement updatecreditScoreBookStmt = connection.prepareStatement(updatecreditScoreBook)) {
            updatecreditScoreBookStmt.setString(1,sagaId);
            updatecreditScoreBookStmt.executeUpdate();
            logger.debug(SUCCESS);
        }catch (SQLException e) {
            logger.error(FAILURE);
            updateRslt=-1;
        }
        return updateRslt > 0;
    }

    /**
     *validateOssn validates OSSN and respective customer.
     */
    public static  boolean validateOssn(Connection connection , CreditScoreDTO payload){

        var validateRslt = 1;
        var validateQuery = "SELECT COUNT(*) from credit_score_db where ossn = ? and full_name = ?";
        try (PreparedStatement validateQueryStmt = connection.prepareStatement(validateQuery)) {
            validateQueryStmt.setString(1,payload.getOssn());
            validateQueryStmt.setString(2,payload.getFullName());

             validateQueryStmt.executeUpdate();

             var rs = validateQueryStmt.getResultSet();
            if (rs.next()) {
                var count = rs.getInt(1);
                if(count!=1){
                    validateRslt=-1;
                }
            }
            logger.debug("Ossn validation successful.");
        }catch (SQLException e) {
            logger.error("Ossn validation failed.");
            validateRslt=-1;
        }
        return validateRslt > 0;
    }

}
