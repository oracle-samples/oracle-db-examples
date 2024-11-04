/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.airline;

import java.io.Reader;
import java.io.StringReader;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.ehcache.Cache;
import org.ehcache.CacheManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import oracle.sql.json.OracleJsonArray;
import oracle.sql.json.OracleJsonException;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonParser;
import oracle.sql.json.OracleJsonValue;

public class FlightService {

    private static final String REG_EXP_REMOVE_QUOTES = "(^\")|(\"$)";
    private static final String ECONOMY_SEATS = "ECONOMY_SEATS";
    private static final String BUSINESS_SEATS = "BUSINESS_SEATS";
    private static final String FIRSTCLASS_SEATS = "FIRSTCLASS_SEATS";
    private Connection connection = null;

    private static final Logger logger = LoggerFactory.getLogger(FlightService.class);
    Cache<String, CompensationData> flightCompensationCache;

    public FlightService(Connection conn, CacheManager cacheManager) throws AirlineException {
        flightCompensationCache = cacheManager.getCache("flightCompensationData", String.class,
                CompensationData.class);

        if (conn == null) {
            throw new AirlineException("Database connection is invalid.");
        }
        this.connection = conn;

    }

    /**
     * Books the flight for the specified passenger by adding the passenger information for the
     * specified flight into the required tables.S
     * 
     * @param flightPayload The payload containing the passenger information required to book the
     *                      flight.
     * @param sagaId        The saga id associated with the request.
     * @return True if the flight booked successfully, otherwise false.
     */
    public boolean bookFlight(String flightPayload, String sagaId) throws AirlineException {
        logger.debug("Flight payload: {}", flightPayload);
        long start = System.currentTimeMillis();
        long end = 0;

        CompensationData flightCompensationInfo = new CompensationData();
        flightCompensationInfo.setSagaId(sagaId);
        boolean bookFlightSuccess = true;

        Reader inputReader = new StringReader(flightPayload);
        OracleJsonFactory jsonFactory = new OracleJsonFactory();

        try (OracleJsonParser parser = jsonFactory.createJsonTextParser(inputReader)) {
            parser.next();
            OracleJsonObject currentJsonObj = parser.getObject();
            OracleJsonArray passengerList = currentJsonObj.get("passengers").asJsonArray();
            Map<Integer, List<String>> trackFlightSeatType = new HashMap<>();

            if (!passengerList.isEmpty()) {
                ArrayList<Integer> listOfPersonId = new ArrayList<>();

                for (OracleJsonValue passenger : passengerList) {
                    OracleJsonObject passengerObj = passenger.asJsonObject();
                    int flightId = Integer.parseInt(passengerObj.getString("flightId"));
                    String seatType = passengerObj.getString("seatType");

                    logger.debug("booking {} on flight {}", seatType, flightId);

                    if (trackFlightSeatType.get(flightId) == null) {
                        trackFlightSeatType.put(flightId, new ArrayList<>());
                    }
                    trackFlightSeatType.get(flightId).add(seatType);

                    int personId = insertPassengers(passengerObj);
                    listOfPersonId.add(personId);
                    if (personId == 0) {
                        bookFlightSuccess = false;
                    }

                    if (!insertPassengersOnFlights(passengerObj, personId)
                            || !updateFlightsSeatCount(flightId, seatType)) {
                        bookFlightSuccess = false;
                    }
                }

                flightCompensationInfo.setPersonIdList(listOfPersonId);
                flightCompensationInfo.setTrackFlightSeatTypesBooked(trackFlightSeatType);
                flightCompensationCache.put(sagaId, flightCompensationInfo);
            }
        } catch (OracleJsonException ex) {
            logger.error("Unable to parse payload", ex);
        }

        logger.debug("booking success? {}", bookFlightSuccess);
        end = System.currentTimeMillis();
        logger.debug("flight booking response time: {}", end - start);
        return bookFlightSuccess;

    }

    /**
     * Inserts the passenger's information into the Passengers table.
     * 
     * @param passenger Json object containing the passenger information.
     * @return The person_id of the passenger that was inserted.
     */
    private int insertPassengers(OracleJsonObject passenger) {
        logger.debug("inserting passenger: {}", passenger);
        String insertPassengerInfo = "INSERT INTO PASSENGERS (FIRST_NAME, MIDDLE_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, EMAIL,PHONE_PRIMARY) VALUES (?,?,?,?,?,?,?)";
        int insertRslt = 0;

        try (PreparedStatement stmt = connection.prepareStatement(insertPassengerInfo,
                new String[] { "PERSON_ID" })) {
            stmt.setString(1,
                    passenger.get("firstName").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            if (passenger.get("middleName") != null) {
                stmt.setString(2, passenger.get("middleName").toString()
                        .replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            } else {
                stmt.setString(2, null);
            }
            stmt.setString(3,
                    passenger.get("lastName").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            String birthDate = passenger.get("birthdate").toString()
                    .replaceAll(REG_EXP_REMOVE_QUOTES, "");
            stmt.setDate(4, Date.valueOf(birthDate));
            stmt.setString(5,
                    passenger.get("gender").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(6,
                    passenger.get("email").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt.setString(7,
                    passenger.get("phonePrimary").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            insertRslt = stmt.executeUpdate();

            if (insertRslt == 1) {
                try (ResultSet keys = stmt.getGeneratedKeys()) {
                    keys.next();
                    return keys.getInt(1);
                }
            }
        } catch (SQLException ex) {
            logger.error("Insert passenger error", ex);
        }
        return insertRslt;
    }

    /**
     * Inserts the information into the passengers_on_flights table with the passenger id, flight
     * information, and seat number.
     * 
     * @param passenger Json object containing the passenger information.
     * @return True if the insert was successful.
     */
    private boolean insertPassengersOnFlights(OracleJsonObject passenger, int personId) {
        String insertPassengerOnFlightInfo = "INSERT INTO passengers_on_flights (FLIGHT_ID, PERSON_ID, SEAT_NUM, SEAT_TYPE) VALUES (?, ?, ?, ?)";
        int insertRslt = 0;
        try (PreparedStatement stmt2 = connection.prepareStatement(insertPassengerOnFlightInfo);
                Statement stmt1 = connection.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                        ResultSet.CONCUR_READ_ONLY)) {
            stmt2.setInt(1, Integer.parseInt(
                    passenger.get("flightId").toString().replaceAll(REG_EXP_REMOVE_QUOTES, "")));
            stmt2.setInt(2, personId);
            stmt2.setString(3,
                    passenger.get("seatNumber").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            stmt2.setString(4,
                    passenger.get("seatType").toString().replaceAll(REG_EXP_REMOVE_QUOTES, ""));
            insertRslt = stmt2.executeUpdate();
            logger.debug("Insert passenger, rows affected: {}", insertRslt);

        } catch (OracleJsonException | SQLException ex) {
            logger.error("Insert passenger on flights error", ex);
        }
        return insertRslt == 1;
    }

    /**
     * Updates the flights seat count for the type of seat the passenger has selected to purchase.
     * 
     * @param flightId The flight id.
     * @param seatType The seat type for the flight.
     * 
     * @return True if the update was successful.
     */
    private boolean updateFlightsSeatCount(int flightId, String seatType) throws AirlineException {
        trackBookedSeatForFlights(flightId, seatType);

        String sanitizedQuery;

        switch (seatType) {
        case ECONOMY_SEATS:
            sanitizedQuery = "UPDATE flights SET economy_seats = economy_seats - 1 WHERE flightid = ?";
            break;
        case BUSINESS_SEATS:
            sanitizedQuery = "UPDATE flights SET business_seats = business_seats - 1 WHERE flightid = ?";
            break;
        case FIRSTCLASS_SEATS:
            sanitizedQuery = "UPDATE flights SET firstclass_seats = firstclass_seats - 1 WHERE flightid = ?";
            break;
        default:
            throw new AirlineException("Unknown seat type: " + seatType);
        }
        int updateRslt = 0;

        try (PreparedStatement stmt = connection.prepareStatement(sanitizedQuery)) {
            stmt.setInt(1, flightId);
            updateRslt = stmt.executeUpdate();
            logger.debug("update seat count rows affected: {}, {}", updateRslt, seatType);
        } catch (SQLException ex) {
            logger.error("Update flight seats error", ex);
        }
        return updateRslt == 1;
    }

    /**
     * Tracks the type of seats being booked for a particular flight by inserting a row into the
     * TRACK_BOOKED_AND_UNBOOKED table so that validation can be done at the end of the test run.
     * 
     * @param flightId The flight id.
     * @param seatType The seat type for the flight.
     */
    private void trackBookedSeatForFlights(int flightId, String seatType) {
        createCountTallyBySeatType(flightId, seatType, true);
    }

    /**
     * Insert a row indicating a booking or unbooking of a flight for a particular seat type into
     * the TRACK_BOOKED_AND_UNBOOKED.
     * 
     * @param flightId The id of the flight.
     * @param seatType The type of seat to book or unbook
     * @param booked   A boolean of true to indicate that a booking is being performed false if an
     *                 unbooking is being performed.
     */
    private void createCountTallyBySeatType(int flightId, String seatType, boolean booked) {
        try {
            switch (seatType) {
            case ECONOMY_SEATS:
                insertIntoTrackBookedAndUnBooked(flightId,
                        booked ? "ECONOMY_BOOKED" : "ECONOMY_UNBOOKED");
                break;
            case BUSINESS_SEATS:
                insertIntoTrackBookedAndUnBooked(flightId,
                        booked ? "BUSINESS_BOOKED" : "BUSINESS_UNBOOKED");
                break;
            case FIRSTCLASS_SEATS:
                insertIntoTrackBookedAndUnBooked(flightId,
                        booked ? "FIRSTCLASS_BOOKED" : "FIRSTCLASS_UNBOOKED");
                break;
            default:
                logger.error("Invalid seat type specified: {}", seatType);
            }
        } catch (AirlineException e) {
            logger.error("Unable to track tally for flight {}, seatType: {}, booked: {}", flightId,
                    seatType, booked, e);
        }
    }

    /**
     * Tracks the type of seats being unbooked for a particular flight by inserting a row into the
     * TRACK_BOOKED_AND_UNBOOKED table so that validation can be done at the end of the test run.
     * 
     * @param flightCompensationInfo The flight compensation information.
     * 
     */
    public void trackUnBookedSeatForFlights(CompensationData flightCompensationInfo) {
        Map<Integer, List<String>> mappedSeatTypesBooked = flightCompensationInfo
                .getTrackFlightSeatTypesBooked();

        for (Map.Entry<Integer, List<String>> entry : mappedSeatTypesBooked.entrySet()) {
            entry.getValue().forEach(
                    seatType -> createCountTallyBySeatType(entry.getKey(), seatType, false));
        }
    }

    /**
     * Insert a row in to the TRACK_BOOKED_AND_UNBOOKED table to indicate the flight and seat type
     * that is being booked or unbooked.
     * 
     * @param flightId                The flight id to track the booked and unbooked seat type for.
     * @param bookedOrUnbookedColName The booked or unbooked seat type column name.
     */
    private void insertIntoTrackBookedAndUnBooked(int flightId, String bookedOrUnbookedColName)
            throws AirlineException {
        String insertSql = "INSERT INTO track_booked_and_unbooked (FLIGHTID, ECONOMY_BOOKED, ECONOMY_UNBOOKED, BUSINESS_BOOKED, BUSINESS_UNBOOKED, FIRSTCLASS_BOOKED, FIRSTCLASS_UNBOOKED) VALUES(?,?,?,?,?,?,?)";

        try (PreparedStatement stmt = connection.prepareStatement(insertSql)) {
            stmt.setInt(1, flightId);
            stmt.setNull(2, java.sql.Types.INTEGER);
            stmt.setNull(3, java.sql.Types.INTEGER);
            stmt.setNull(4, java.sql.Types.INTEGER);
            stmt.setNull(5, java.sql.Types.INTEGER);
            stmt.setNull(6, java.sql.Types.INTEGER);
            stmt.setNull(7, java.sql.Types.INTEGER);

            switch (bookedOrUnbookedColName) {
            case "ECONOMY_BOOKED":
                stmt.setInt(2, 1);
                break;
            case "ECONOMY_UNBOOKED":
                stmt.setInt(3, 1);
                break;
            case "BUSINESS_BOOKED":
                stmt.setInt(4, 1);
                break;
            case "BUSINESS_UNBOOKED":
                stmt.setInt(5, 1);
                break;
            case "FIRSTCLASS_BOOKED":
                stmt.setInt(6, 1);
                break;
            case "FIRSTCLASS_UNBOOKED":
                stmt.setInt(7, 1);
                break;
            default:
                throw new AirlineException("Unable to insert row tracking count for "
                        + bookedOrUnbookedColName + " for flight " + flightId);
            }
            stmt.executeUpdate();

        } catch (SQLException ex) {
            throw new AirlineException("Unable to insert row tracking count for "
                    + bookedOrUnbookedColName + " for flight " + flightId, ex);
        }
    }

    /**
     * Remove the specified passenger from the passengers list.
     * 
     * @param personId The id of the passenger to remove.
     * @return True if the delete was successful
     */
    public boolean rollbackInvalidFlightBooking(List<Integer> personId) {
        List<String> placeholders = new ArrayList<>();

        for (int i = 0; i < personId.size(); ++i) {
            placeholders.add("?");
        }

        String placeholder = String.join(",", placeholders);

        String deleteInvalidBooking = "Delete from PASSENGERS where PERSON_ID in (" + placeholder
                + ")";
        logger.debug("deleteInvalidBooking: {} => {}", deleteInvalidBooking, personId);
        int deleteRslt = 0;
        try (PreparedStatement stmt = connection.prepareStatement(deleteInvalidBooking)) {
            for (int i = 0; i < personId.size(); ++i) {
                stmt.setInt(i + 1, personId.get(i));
            }
            deleteRslt = stmt.executeUpdate();
        } catch (OracleJsonException | SQLException ex) {
            logger.error("Remove passenger on flights error", ex);
        }
        return deleteRslt == personId.size();
    }

}
