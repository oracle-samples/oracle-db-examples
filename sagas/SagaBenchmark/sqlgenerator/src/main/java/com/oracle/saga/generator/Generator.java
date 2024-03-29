/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.generator;

import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.util.Calendar;
import java.util.Properties;
import java.util.Random;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.oracle.saga.travelagency.util.PropertiesHelper;

/**
 * Generate SQL files for the saga benchmark.
 */
public class Generator {

    private static final Logger logger = LoggerFactory.getLogger(Generator.class);

    private static Random random = new SecureRandom();

    private static final String GENERATING = "Generating {}";
    private static final String SERVER_OUTPUT = "set serveroutput on%n";

    public static void main(String[] args) throws Exception {
        Properties p = PropertiesHelper.loadProperties();
        int participantCount = 3;
        logger.info("participantCount: {}", participantCount);

        String rawQueuePartitionCount = p.getProperty("queuePartitions", "1");
        int queuePartitionCount = Integer.parseInt(rawQueuePartitionCount);
        logger.info("queuePartitionCount: {}", queuePartitionCount);

        String rawFlightCount = p.getProperty("numOfFlightsToCreate", "10");
        int flightCount = Integer.parseInt(rawFlightCount);
        logger.info("flightCount: {}", flightCount);

        String setupPDBsPath = "sql/setupPDBs.sql";
        generateSetupPDBs(setupPDBsPath, participantCount);

        String travelAgencyPath = "sql/travelagency.sql";
        generateTravelAgency(travelAgencyPath, queuePartitionCount);

        String airlinePath = "sql/airline.sql";
        generateAirline(airlinePath, queuePartitionCount, flightCount);

        String carPath = "sql/car.sql";
        generateCar(carPath, queuePartitionCount);
    }

    /**
     * Generate SQL file that creates each of the PDBs and sets up permissions
     * 
     * @param path             Where to generate the file to
     * @param participantCount The number of participants
     * @throws IOException If there is a problem with the path
     */
    private static void generateSetupPDBs(String path, int participantCount) throws IOException {
        logger.info(GENERATING, path);
        FileWriter fileWriter = new FileWriter(path);
        PrintWriter printWriter = new PrintWriter(fileWriter);

        printWriter.printf(SERVER_OUTPUT);
        printWriter.printf("alter pluggable database all close immediate INSTANCES=ALL;%n");
        for (int i = 1; i <= participantCount; ++i) {
            printWriter.printf("drop pluggable database cdb1_pdb%d including datafiles;%n", i);
            printWriter.printf(
                    "create pluggable database cdb1_pdb%d admin user admin identified by test file_name_convert=(<seed_database>, 'pdb%d');%n",
                    i, i);
        }
        printWriter.println();

        printWriter.printf("ALTER PLUGGABLE DATABASE ALL OPEN;%n");

        printWriter.println();

        for (int i = 1; i <= participantCount; ++i) {
            printWriter.printf("alter session set container=cdb1_pdb%d;%n", i);
            printWriter.printf("--drop tablespace users including contents and datafiles;%n");
            printWriter.printf(
                    "create tablespace users datafile 'users%d.dbf' size 500m autoextend on MAXSIZE 5000M;%n",
                    i);

            for (int j = 1; j <= participantCount; ++j) {
                if (j == i) {
                    continue;
                }
                printWriter.printf(
                        "CREATE PUBLIC DATABASE LINK PDB%d_LINK CONNECT TO admin IDENTIFIED BY test USING 'cdb1_pdb%d';%n",
                        j, j);
            }

            printWriter.printf("ALTER USER admin DEFAULT TABLESPACE users;%n");
            printWriter.println();
        }

        for (int i = 1; i <= participantCount; ++i) {
            printWriter.printf("alter session set container=cdb1_pdb%d;%n", i);
            printWriter.printf("--grant aq_administrator_role to admin;%n");
            printWriter.printf("grant connect,resource,unlimited tablespace to admin;%n");
            printWriter.printf("--grant execute on sys.dbms_saga_adm to admin;%n");
            printWriter.printf("--grant execute on sys.dbms_saga to admin;%n");
            printWriter.printf("grant saga_adm_role to admin;%n");
            printWriter.printf("grant saga_participant_role to admin;%n");
            printWriter.printf("grant saga_connect_role to admin;%n");
            printWriter.printf("grant all on sys.saga_message_broker$ to admin;%n");
            printWriter.printf("grant all on sys.saga_participant$ to admin;%n");
            printWriter.printf("grant all on sys.saga$ to admin;%n");
            printWriter.printf("grant all on sys.saga_participant_set$ to admin;%n");

            printWriter.println();
        }

        printWriter.close();
    }

    private static void generateCar(String path, int queuePartition) throws IOException {
        logger.info(GENERATING, path);
        FileWriter fileWriter = new FileWriter(path);
        PrintWriter printWriter = new PrintWriter(fileWriter);

        printWriter.printf(SERVER_OUTPUT);

        printWriter.println();

        printWriter.printf(
                "exec dbms_saga_adm.add_participant(participant_name=> 'Car' ,dblink_to_broker => 'pdb1_link',mailbox_schema=> 'admin',broker_name=> 'TEST', dblink_to_participant=> 'pdb3_link', queue_partitions => %d);%n",
                queuePartition);

        printWriter.println();

        printWriter.printf("CREATE TABLE CATEGORY(%n");
        printWriter
                .printf("  ID NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,%n");
        printWriter.printf("  NAME VARCHAR2(50) NOT NULL,%n");
        printWriter.printf("  PRIMARY KEY (ID)%n");
        printWriter.printf(");%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE COMPANIES(%n");
        printWriter
                .printf("  ID NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,%n");
        printWriter.printf("  NAME VARCHAR2(255) NOT NULL,%n");
        printWriter.printf("  PRIMARY KEY (ID)%n");
        printWriter.printf(");%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE CARS(%n");
        printWriter
                .printf("  ID NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,%n");
        printWriter.printf("  COMPANY_ID NUMBER NOT NULL,%n");
        printWriter.printf("  CATEGORY_ID NUMBER NOT NULL,%n");
        printWriter.printf("  MODEL VARCHAR2(255) NOT NULL,%n");
        printWriter.printf("  STATUS NUMBER(1,0) NOT NULL,%n");
        printWriter.printf("  PRIMARY KEY (ID),%n");
        printWriter.printf("  CONSTRAINT CK_STATUS CHECK (STATUS IN (0,1)),%n");
        printWriter.printf(
                "  FOREIGN KEY (COMPANY_ID) REFERENCES \"ADMIN\".\"COMPANIES\"(ID) ON DELETE CASCADE,%n");
        printWriter.printf(
                "  FOREIGN KEY (CATEGORY_ID) REFERENCES \"ADMIN\".\"CATEGORY\"(ID) ON DELETE CASCADE%n");
        printWriter.printf(");%n");

        printWriter.printf("CREATE INDEX status_ind ON CARS (STATUS);%n");
        printWriter.printf("CREATE INDEX category_ind ON CARS (CATEGORY_ID);%n");
        printWriter.printf("CREATE INDEX company_ind ON CARS (COMPANY_ID);%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE CUSTOMERS(%n");
        printWriter
                .printf("  ID NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,%n");
        printWriter.printf("  FULL_NAME VARCHAR2(255) NOT NULL,%n");
        printWriter.printf("  PHONE VARCHAR2(20) NOT NULL,%n");
        printWriter.printf("  DRIVERS_LICENSE VARCHAR2(32),%n");
        printWriter.printf("  BIRTH_DATE DATE NOT NULL,%n");
        printWriter.printf("  PRIMARY KEY (ID)%n");
        printWriter.printf(");%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE RENTALS(%n");
        printWriter
                .printf("  ID NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,%n");
        printWriter.printf("  CUSTOMER_ID NUMBER NOT NULL,%n");
        printWriter.printf("  START_DATE DATE NOT NULL,%n");
        printWriter.printf("  END_DATE DATE NOT NULL,%n");
        printWriter.printf("  CAR_ID NUMBER NOT NULL,%n");
        printWriter.printf("  PRIMARY KEY (ID),%n");
        printWriter.printf(
                "  FOREIGN KEY (CUSTOMER_ID) REFERENCES \"ADMIN\".\"CUSTOMERS\"(ID) ON DELETE CASCADE,%n");
        printWriter.printf(
                "  FOREIGN KEY (CAR_ID) REFERENCES \"ADMIN\".\"CARS\"(ID) ON DELETE CASCADE%n");
        printWriter.printf(");%n");

        printWriter.printf("CREATE INDEX customer_ind ON RENTALS (CUSTOMER_ID);%n");
        printWriter.printf("CREATE INDEX car_ind ON RENTALS (CAR_ID);%n");

        printWriter.println();

        printWriter.printf("INSERT INTO CATEGORY (NAME) VALUES ('COMPACT');%n");
        printWriter.printf("INSERT INTO CATEGORY (NAME) VALUES ('SUV');%n");
        printWriter.printf("INSERT INTO CATEGORY (NAME) VALUES ('VAN');%n");
        printWriter.printf("INSERT INTO CATEGORY (NAME) VALUES ('TRUCK');%n");
        printWriter.printf("INSERT INTO CATEGORY (NAME) VALUES ('LUXURY');%n");

        printWriter.println();

        printWriter.printf("INSERT INTO COMPANIES (NAME) VALUES ('Enterprise');%n");
        printWriter.printf("INSERT INTO COMPANIES (NAME) VALUES ('Hertz');%n");
        printWriter.printf("INSERT INTO COMPANIES (NAME) VALUES ('Budget');%n");

        printWriter.println();

        for (int i = 1; i <= 3; ++i) {
            for (int j = 0; j < 10; ++j) {
                printWriter.printf(
                        "INSERT INTO CARS(COMPANY_ID, CATEGORY_ID, MODEL, STATUS) values(%d, 1, 'Honda Civic', 1);%n",
                        i);
                printWriter.printf(
                        "INSERT INTO CARS(COMPANY_ID, CATEGORY_ID, MODEL, STATUS) values(%d, 2, 'Honda Pilot', 1);%n",
                        i);
                printWriter.printf(
                        "INSERT INTO CARS(COMPANY_ID, CATEGORY_ID, MODEL, STATUS) values(%d, 3, 'Honda Odyssey', 1);%n",
                        i);
                printWriter.printf(
                        "INSERT INTO CARS(COMPANY_ID, CATEGORY_ID, MODEL, STATUS) values(%d, 4, 'Toyota Tundra', 1);%n",
                        i);
                printWriter.printf(
                        "INSERT INTO CARS(COMPANY_ID, CATEGORY_ID, MODEL, STATUS) values(%d, 5, 'Audi A8', 1);%n",
                        i);
            }

        }

        printWriter.close();
    }

    /**
     * Generates a SQL file for the airline participant.
     * 
     * @param path           The path of the files
     * @param queuePartition The number of queue partitions
     * @param flightCount    The number of flights to generate
     * @throws IOException If there is a problem with the path.
     */
    private static void generateAirline(String path, int queuePartition, int flightCount)
            throws IOException {

        logger.info(GENERATING, path);
        FileWriter fileWriter = new FileWriter(path);
        PrintWriter printWriter = new PrintWriter(fileWriter);

        printWriter.printf(SERVER_OUTPUT);

        printWriter.println();

        printWriter.printf(
                "exec dbms_saga_adm.add_participant(participant_name=> 'Airline' ,dblink_to_broker => 'pdb1_link',mailbox_schema=> 'admin',broker_name=> 'TEST', dblink_to_participant=> 'pdb2_link', queue_partitions => %d);%n",
                queuePartition);

        printWriter.println();

        printWriter.printf("CREATE TABLE AIRLINE_COMPANY(%n");
        printWriter.printf("  ID NUMBER primary key,%n");
        printWriter.printf("  NAME VARCHAR2(25 BYTE) NOT NULL%n");
        printWriter.printf(");%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE FLIGHTS (%n");
        printWriter.printf("  FLIGHTID NUMBER NOT NULL primary key,%n");
        printWriter.printf("  COMPANYID NUMBER NOT NULL,%n");
        printWriter.printf("  FROM_DESTINATION VARCHAR2(30) NOT NULL,%n");
        printWriter.printf("  TO_DESTINATION VARCHAR2(30) NOT NULL,%n");
        printWriter.printf("  DEPARTURE TIMESTAMP(6) NOT NULL,%n");
        printWriter.printf("  ARRIVAL TIMESTAMP(6) NOT NULL,%n");
        printWriter.printf(
                "  ECONOMY_SEATS NUMBER reservable constraint economyseats_con check(economy_seats between 0 and 100000),%n");
        printWriter.printf(
                "  BUSINESS_SEATS NUMBER reservable constraint businessseats_con check(business_seats between 0 and 100000), %n");
        printWriter.printf(
                "  FIRSTCLASS_SEATS NUMBER reservable constraint firstclassseats_con check(firstclass_seats between 0 and 100000),%n");
        printWriter.printf("  STATUS VARCHAR2(10) NOT NULL%n");
        printWriter.printf(");%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE TRACK_FLIGHT_SEATS (%n");
        printWriter.printf("  FLIGHTID NUMBER,%n");
        printWriter.printf("  ECONOMY_INITIAL NUMBER DEFAULT 0,%n");
        printWriter.printf("  BUSINESS_INITIAL NUMBER DEFAULT 0,%n");
        printWriter.printf("  FIRSTCLASS_INITIAL NUMBER DEFAULT 0,%n");
        printWriter.printf("  PRIMARY KEY (FLIGHTID)%n");
        printWriter.printf(");%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE TRACK_BOOKED_AND_UNBOOKED (%n");
        printWriter.printf("  FLIGHTID NUMBER NOT NULL,%n");
        printWriter.printf("  ECONOMY_BOOKED NUMBER DEFAULT 0,%n");
        printWriter.printf("  ECONOMY_UNBOOKED NUMBER DEFAULT 0,%n");
        printWriter.printf("  BUSINESS_BOOKED NUMBER DEFAULT 0,%n");
        printWriter.printf("  BUSINESS_UNBOOKED NUMBER DEFAULT 0,%n");
        printWriter.printf("  FIRSTCLASS_BOOKED NUMBER DEFAULT 0,%n");
        printWriter.printf("  FIRSTCLASS_UNBOOKED NUMBER DEFAULT 0%n");
        printWriter.printf(");%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE PASSENGERS (%n");
        printWriter.printf(
                "  person_id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,%n");
        printWriter.printf("  first_name VARCHAR(50) NOT NULL,%n");
        printWriter.printf("  middle_name VARCHAR(50),%n");
        printWriter.printf("  last_name VARCHAR(50) NOT NULL,%n");
        printWriter.printf("  date_of_birth DATE NOT NULL,%n");
        printWriter.printf("  gender CHAR(1) NOT NULL,%n");
        printWriter.printf("  email VARCHAR(256) NOT NULL,%n");
        printWriter.printf("  phone_primary CHAR(15) NOT NULL,%n");
        printWriter.printf("  CONSTRAINT valid_gender CHECK (gender = 'M' OR gender = 'F'),%n");
        printWriter.printf("  PRIMARY KEY (person_id)%n");
        printWriter.printf(");%n");

        printWriter.println();

        printWriter.printf("CREATE TABLE passengers_on_flights (%n");
        printWriter.printf("  flight_id INTEGER NOT NULL,%n");
        printWriter.printf("  person_id INTEGER NOT NULL,%n");
        printWriter.printf("  seat_num CHAR(3) NOT NULL,%n");
        printWriter.printf("  seat_type VARCHAR(50) NOT NULL,%n");
        printWriter.printf("  PRIMARY KEY (flight_id, person_id),%n");
        printWriter.printf(
                "  FOREIGN KEY (person_id) REFERENCES \"ADMIN\".\"PASSENGERS\"(person_id) ON DELETE CASCADE%n");
        printWriter.printf(");%n");

        printWriter.printf("CREATE INDEX passenger_ind ON passengers_on_flights (person_id);%n");

        printWriter.println();

        printWriter.printf("%s%n", generateFlightList(flightCount));

        printWriter.println();

        printWriter.printf(
                "-- The benchmark driver will automatically generate a list of flights, but this one can be used if doing manual testing via a REST client%n");
        printWriter.printf(
                "insert into FLIGHTS values(1, 3, 'LAX', 'HNL', TO_TIMESTAMP('2013-05-18 13:18', 'YYYY-MM-DD HH24:MI'), TO_TIMESTAMP('2013-05-18 23:23', 'YYYY-MM-DD HH24:MI'), 100000, 100000, 100000, 'Available');%n");

        printWriter.println();
        printWriter.close();

    }

    /**
     * Creates a random timestamp.
     * 
     * @return The random timestamp
     */
    private static Timestamp getRandomTime() {
        int low = 100;
        int high = 1500;
        int result = random.nextInt(high - low) + low;
        int resultSec = random.nextInt(high - low) + low;

        Calendar calendar = Calendar.getInstance();
        calendar.add(Calendar.MINUTE, -result);
        calendar.add(Calendar.SECOND, -resultSec);

        return new java.sql.Timestamp(calendar.getTimeInMillis());
    }

    /**
     * Generate the list of flights
     * 
     * @param flightCount The number of flights to generate
     * @return A string of SQL that inserts the airline companies as well as the flight list itself
     */
    private static String generateFlightList(int flightCount) {
        String[] companyNames = { "American", "Delta", "United Airlines", "Virgin", "South West" };
        String[] airportNames = { "LAX", "JFK", "HNL", "ONT" };

        StringWriter writer = new StringWriter();
        PrintWriter printWriter = new PrintWriter(writer);

        for (int i = 0; i < companyNames.length; ++i) {
            printWriter.printf("INSERT INTO AIRLINE_COMPANY VALUES(%d,'%s');%n", i + 1,
                    companyNames[i]);
        }

        printWriter.println();

        for (int i = 0; i < flightCount; ++i) {
            printWriter.printf(
                    "INSERT INTO FLIGHTS (FLIGHTID, COMPANYID, FROM_DESTINATION, TO_DESTINATION,DEPARTURE, ARRIVAL, ECONOMY_SEATS, BUSINESS_SEATS, FIRSTCLASS_SEATS,STATUS) VALUES (%d, %d, '%s', '%s', TO_TIMESTAMP('%s', 'YYYY-MM-DD HH24:MI:SS.FF'), TO_TIMESTAMP('%s', 'YYYY-MM-DD HH24:MI:SS.FF'), %d, %d, %d, '%s');%n",
                    200 + i, random.nextInt(companyNames.length) + 1,
                    airportNames[random.nextInt(airportNames.length)],
                    airportNames[random.nextInt(airportNames.length)], getRandomTime(),
                    getRandomTime(), 100000, 100000, 100000, "Available");
        }

        return writer.toString();

    }

    /**
     * Generate the SQL file for the travel agency.
     * 
     * @param path           The path to save the file to
     * @param queuePartition The number of queue partitions
     * @throws IOException If there is a problem with the path
     */
    private static void generateTravelAgency(String path, int queuePartition) throws IOException {

        logger.info(GENERATING, path);
        FileWriter fileWriter = new FileWriter(path);
        PrintWriter printWriter = new PrintWriter(fileWriter);

        printWriter.printf(SERVER_OUTPUT);

        printWriter.println();

        printWriter.printf(
                "exec dbms_saga_adm.add_broker(broker_name => 'TEST', broker_schema => 'admin', queue_partitions => %d);%n",
                queuePartition);
        printWriter.printf(
                "exec dbms_saga_adm.add_coordinator(coordinator_name => 'TACoordinator', mailbox_schema => 'admin', broker_name => 'TEST', dblink_to_coordinator => 'pdb1_link', queue_partitions => %d);%n",
                queuePartition);
        printWriter.printf(
                "exec dbms_saga_adm.add_participant(participant_name => 'TravelAgency', coordinator_name => 'TACoordinator' , dblink_to_broker => 'pdb1_link' , mailbox_schema => 'admin' , broker_name => 'TEST', dblink_to_participant => 'pdb1_link', queue_partitions => %d);%n",
                queuePartition);

        printWriter.println();

        printWriter.close();

    }
}
