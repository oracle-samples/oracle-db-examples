/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

INSERT INTO flights (id, flight_number, price) values (0, 122, 1000);
INSERT INTO flights (id, flight_number, price) values (1, 123, 2300);
INSERT INTO flights (id, flight_number, price) values (2, 124, 455);

INSERT INTO seats (id, flight_id, available) values (0, 0, TRUE);
INSERT INTO seats (id, flight_id, available) values (1, 1, TRUE);
INSERT INTO seats (id, flight_id, available) values (2, 1, TRUE);

INSERT INTO payment_methods (id) values (0);