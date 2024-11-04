/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.car;

import java.io.Reader;
import java.io.StringReader;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import org.ehcache.Cache;
import org.ehcache.CacheManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import oracle.sql.json.OracleJsonException;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonParser;

public class CarService {

    private static final String REG_EXP_REMOVE_QUOTES = "(^\")|(\"$)";

    private Connection connection = null;
    private static final Logger logger = LoggerFactory.getLogger(CarService.class);
    Cache<String, CompensationData> carCompensationCache;

    public CarService(Connection conn, CacheManager cacheManager) throws CarException {
        carCompensationCache = cacheManager.getCache("carCompensationData", String.class,
                CompensationData.class);
        if (conn == null) {
            throw new CarException("Database connection is invalid.");
        }
        this.connection = conn;
    }

    /**
     * Books the car rental for the specified customer. Adds all the valid rental information to the
     * required table.
     * 
     * @param carPayload The payload containing the information required to process the car rental.
     * @param sagaId     The saga id associated with the request.
     * @return True if the car rental was successful, otherwise false.
     */
    public boolean bookCar(String carPayload, String sagaId) {
        logger.debug("Payload: {}", carPayload);
        long start = System.currentTimeMillis();
        long end = 0;
        Boolean[] bookCarSuccess = { false };

        Reader inputReader = new StringReader(carPayload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject carJsonObj = parser.getObject();

            int custId = insertCustomers(carJsonObj);

            if (custId != 0 && insertRentalInfo(carJsonObj, custId)) {
                CompensationData carCompensationInfo = new CompensationData();
                carCompensationInfo.setSagaId(sagaId);
                carCompensationInfo.setCustomerId(custId);
                carCompensationCache.put(sagaId, carCompensationInfo);
                bookCarSuccess[0] = true;
            } else {
                bookCarSuccess[0] = false;
            }

        } catch (OracleJsonException ex) {
            logger.error("Unable to parse payload", ex);
        }

        end = System.currentTimeMillis();
        logger.debug("booking response time: {}", (end - start));
        return bookCarSuccess[0];

    }

    /**
     * Inserts the customer's information into the Customers table.
     * 
     * @param customer Json object containing the customer information.
     * @return The id of the customer that was inserted.
     */
    private int insertCustomers(OracleJsonObject customer) {
        String insertCustomerInfo = "INSERT INTO CUSTOMERS (FULL_NAME, PHONE, DRIVERS_LICENSE, BIRTH_DATE) VALUES (?,?,?,?)";
        int insertRslt = 0;

        try (PreparedStatement stmt = connection.prepareStatement(insertCustomerInfo,
                new String[] { "ID" })) {
            stmt.setString(1,
                    customer.get("customer").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(2,
                    customer.get("phone").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));

            stmt.setString(3, customer.get("driversLicense").toString()
                    .replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            String birthDate = customer.get("birthdate").toString()
                    .replaceAll(REG_EXP_REMOVE_QUOTES, "");
            stmt.setDate(4, Date.valueOf(birthDate));
            insertRslt = stmt.executeUpdate();

            if (insertRslt == 1) {
                ResultSet keys = stmt.getGeneratedKeys();
                keys.next();
                return keys.getInt(1);
            }

        } catch (SQLException ex) {
            logger.error("Insert customers error", ex);
        }
        return insertRslt;
    }

    /**
     * Gets the Id value for the specified category name stored in the Category table.
     * 
     * @param carType The type of car the customer is looking to rent.
     * @return The Id of the selected category.
     */
    private int getCategoryID(String carType) {
        String getCategoryId = "SELECT ID FROM CATEGORY WHERE NAME = ?";
        int categoryId = 0;
        try (PreparedStatement stmt = connection.prepareStatement(getCategoryId)) {
            stmt.setString(1, carType.toUpperCase());
            try (ResultSet rslt = stmt.executeQuery();) {
                rslt.next();
                categoryId = rslt.getInt("ID");
            }
        } catch (SQLException ex) {
            logger.error("Get category id error", ex);
        }
        return categoryId;
    }

    /**
     * Get the Id of the available car that the customer will be renting.
     * 
     * @param carType The type of car the customer is looking to rent.
     * @return The Id of the car the customer will be renting.
     */
    private int getAvailableCarType(String carType) {
        int categoryId = getCategoryID(carType);
        String selectAvailableCarType = "SELECT ID FROM CARS WHERE CATEGORY_ID = ? AND STATUS = 1 ORDER BY dbms_random.value OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY";
        int availableCarId = 0;
        try (PreparedStatement stmt = connection.prepareStatement(selectAvailableCarType)) {
            stmt.setInt(1, categoryId);
            try (ResultSet rslt = stmt.executeQuery()) {
                rslt.next();
                availableCarId = rslt.getInt("ID");
            }
        } catch (SQLException ex) {
            logger.error("Get available car type error", ex);
        }
        return availableCarId;
    }

    /**
     * Inserts the rental information into the Rentals table.
     * 
     * @param customer Json object containing the customer information.
     * @return True if the insert was successful.
     */
    private boolean insertRentalInfo(OracleJsonObject customer, int id) {
        int carId = getAvailableCarType(
                customer.getString("carType").replaceAll(REG_EXP_REMOVE_QUOTES, ""));
        String insertRentalInfo = "INSERT INTO RENTALS (CUSTOMER_ID, START_DATE, END_DATE, CAR_ID) VALUES (?, ?, ?, ?)";
        int insertRslt = 0;
        try (PreparedStatement stmt2 = connection.prepareStatement(insertRentalInfo);
                Statement stmt1 = connection.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                        ResultSet.CONCUR_READ_ONLY)) {
            stmt2.setInt(1, id);
            String startDate = customer.get("startDate").toString()
                    .replaceAll(REG_EXP_REMOVE_QUOTES, "");
            stmt2.setDate(2, Date.valueOf(startDate));
            String endDate = customer.get("endDate").toString().replaceAll(REG_EXP_REMOVE_QUOTES,
                    "");
            stmt2.setDate(3, Date.valueOf(endDate));
            stmt2.setInt(4, carId);
            insertRslt = stmt2.executeUpdate();

        } catch (SQLException ex) {
            logger.error("Insert rental error", ex);
        }
        return insertRslt == 1;
    }

    /**
     * Remove the specified customer from the customers table and rentals table when a rollback is
     * invoked.
     * 
     * @param customerId The id of the customer to remove.
     * @return True if the delete was successful
     */
    public boolean rollbackInvalidCarBooking(int customerId) {
        logger.debug("Deleting invalid car booking for customer id: {}", customerId);
        String deleteInvalidCarBooking = "Delete from CUSTOMERS where ID = ?";
        int deleteRslt = 0;
        try (PreparedStatement stmt = connection.prepareStatement(deleteInvalidCarBooking)) {
            stmt.setInt(1, customerId);
            deleteRslt = stmt.executeUpdate();
        } catch (OracleJsonException | SQLException ex) {
            logger.error("Remove customer and car rental error", ex);
        }
        return deleteRslt > 0;
    }

}
