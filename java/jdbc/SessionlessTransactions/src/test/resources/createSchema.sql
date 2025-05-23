/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

CREATE TABLE bookings (
    id NUMBER GENERATED ALWAYS AS IDENTITY,
    created_at DATE,
    CONSTRAINT BOOKING_PK PRIMARY KEY (id)
);/

CREATE TABLE flights (
    id NUMBER,
    flight_number VARCHAR(255),
    origin VARCHAR(255),
    destination VARCHAR(255),
    departure TIMESTAMP,
    price NUMBER,
    CONSTRAINT FLIGHT_PK PRIMARY KEY (id)
);/

CREATE TABLE seats (
    id NUMBER,
    flight_id NUMBER NOT NULL,
    available BOOLEAN NOT NULL,
    CONSTRAINT SEAT_PK PRIMARY KEY (id),
    CONSTRAINT SEAT_FLIGHT_FK FOREIGN KEY (flight_id) REFERENCES flights(id)
);/

CREATE TABLE tickets (
    id NUMBER GENERATED ALWAYS AS IDENTITY,
    seat_id NUMBER NOT NULL,
    booking_id NUMBER NOT NULL,
    CONSTRAINT TICKET_PK PRIMARY KEY (id),
    CONSTRAINT TICKET_SEATS_FK FOREIGN KEY (seat_id) REFERENCES seats(id),
    CONSTRAINT TICKET_BOOKINGS_FK FOREIGN KEY (booking_id) REFERENCES bookings(id)
);/

CREATE TABLE payment_methods (
    id NUMBER,
    CONSTRAINT PAYMENT_METHOD_PK PRIMARY KEY (id)
);/

CREATE TABLE receipts (
    id NUMBER GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP,
    receipt_number VARCHAR(255),
    total NUMBER,
    booking_id NUMBER,
    payment_method_id NUMBER,
    CONSTRAINT RECEIPT_PK PRIMARY KEY (id),
    CONSTRAINT RECEIPT_BOOKING_FK FOREIGN KEY (booking_id) REFERENCES bookings(id),
    CONSTRAINT RECEIPT_PAYMENT_M_FK FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
);/

CREATE OR REPLACE PROCEDURE fetch_seats(
  f_id IN NUMBER,
  n_rows IN INT,
  t_data OUT DBMS_SQL.NUMBER_TABLE
) AS
  CURSOR c IS
    SELECT id FROM seats
    WHERE available = 1 AND flight_id = f_id
    FOR UPDATE SKIP LOCKED;
BEGIN
    OPEN c;
    FETCH c BULK COLLECT INTO t_data LIMIT n_rows;
    CLOSE c;
END fetch_seats;