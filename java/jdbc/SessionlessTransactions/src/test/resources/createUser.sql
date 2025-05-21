/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

CREATE USER test_user IDENTIFIED BY test_password;
GRANT CREATE SESSION TO test_user;
GRANT CREATE TABLE TO test_user;
GRANT CREATE SEQUENCE TO test_user;
GRANT DROP ANY TABLE TO test_user;
GRANT UNLIMITED TABLESPACE TO test_user;