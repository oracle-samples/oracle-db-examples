/* Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved. */

/******************************************************************************
 *
 * You may not use the identified files except in compliance with the Apache
 * License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * NAME
 *   demo.sql
 *
 * DESCRIPTION
 *   Create database objects for the examples in your database user account.
 *
 *   The video https://www.youtube.com/watch?v=WDJacg0NuLo
 *   shows how to create a new database user.
 *
 *   Scripts to create Oracle Database's traditional sample schemas can
 *   be found at: https://github.com/oracle/db-sample-schemas
 *
 *****************************************************************************/

SET ECHO ON

-- For plsqlproc.js example for bind parameters
CREATE OR REPLACE PROCEDURE testproc (p_in IN VARCHAR2, p_inout IN OUT VARCHAR2, p_out OUT NUMBER)
AS
BEGIN
  p_inout := p_in || p_inout;
  p_out := 101;
END;
/
SHOW ERRORS

-- For plsqlfunc.js example on calling a PL/SQL function
CREATE OR REPLACE FUNCTION testfunc (p1_in IN VARCHAR2, p2_in IN VARCHAR2) RETURN VARCHAR2
AS
BEGIN
  RETURN p1_in || p2_in;
END;
/
SHOW ERRORS

-- For refcursor.js example of REF CURSORS
CREATE OR REPLACE PROCEDURE get_emp_rs (p_sal IN NUMBER, p_recordset OUT SYS_REFCURSOR)
AS
BEGIN
  OPEN p_recordset FOR
    SELECT first_name, salary, hire_date
    FROM   employees
    WHERE  salary > p_sal;
END;
/
SHOW ERRORS

-- For plsqlarray.js example for PL/SQL 'INDEX BY' array binds
BEGIN EXECUTE IMMEDIATE 'DROP TABLE waveheight'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/

CREATE TABLE waveheight (beach VARCHAR2(50), depth NUMBER);

CREATE OR REPLACE PACKAGE beachpkg IS
  TYPE beachType IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
  TYPE depthType IS TABLE OF NUMBER       INDEX BY BINARY_INTEGER;
  PROCEDURE array_in(beaches IN beachType, depths IN depthType);
  PROCEDURE array_out(beaches OUT beachType, depths OUT depthType);
  PROCEDURE array_inout(beaches IN OUT beachType, depths IN OUT depthType);
END;
/
SHOW ERRORS

CREATE OR REPLACE PACKAGE BODY beachpkg IS

  -- Insert array values into a table
  PROCEDURE array_in(beaches IN beachType, depths IN depthType) IS
  BEGIN
    IF beaches.COUNT <> depths.COUNT THEN
       RAISE_APPLICATION_ERROR(-20000, 'Array lengths must match for this example.');
    END IF;
    FORALL i IN INDICES OF beaches
      INSERT INTO waveheight (beach, depth) VALUES (beaches(i), depths(i));
  END;

  -- Return the values from a table
  PROCEDURE array_out(beaches OUT beachType, depths OUT depthType) IS
  BEGIN
    SELECT beach, depth BULK COLLECT INTO beaches, depths FROM waveheight;
  END;

  -- Return the arguments sorted
  PROCEDURE array_inout(beaches IN OUT beachType, depths IN OUT depthType) IS
  BEGIN
    IF beaches.COUNT <> depths.COUNT THEN
       RAISE_APPLICATION_ERROR(-20001, 'Array lengths must match for this example.');
    END IF;
    FORALL i IN INDICES OF beaches
      INSERT INTO waveheight (beach, depth) VALUES (beaches(i), depths(i));
    SELECT beach, depth BULK COLLECT INTO beaches, depths FROM waveheight ORDER BY 1;
  END;

END;
/
SHOW ERRORS

-- For selectjson.js example of JSON datatype. Requires Oracle Database 12.1.0.2
BEGIN EXECUTE IMMEDIATE 'DROP TABLE j_purchaseorder'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/

-- Note if your applications always insert valid JSON, you may delete
-- the IS JSON check to remove its additional validation overhead.
CREATE TABLE j_purchaseorder (po_document VARCHAR2(4000) CHECK (po_document IS JSON));

-- For selectjsonblob.js example of JSON datatype.  Requires Oracle Database 12.1.0.2
BEGIN EXECUTE IMMEDIATE 'DROP TABLE j_purchaseorder_b'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/
CREATE TABLE j_purchaseorder_b (po_document BLOB CHECK (po_document IS JSON)) LOB (po_document) STORE AS (CACHE);

-- For DML RETURNING aka RETURNING INTO examples
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dmlrupdtab'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/
CREATE TABLE dmlrupdtab (id NUMBER, name VARCHAR2(40));
INSERT INTO dmlrupdtab VALUES (1001, 'Venkat');
INSERT INTO dmlrupdtab VALUES (1002, 'Neeharika');

-- For LOB examples
BEGIN EXECUTE IMMEDIATE 'DROP TABLE mylobs'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/
CREATE TABLE mylobs (id NUMBER, c CLOB, b BLOB);

-- For lobbinds.js: Procedure to show IN bind support for LOBs
CREATE OR REPLACE PROCEDURE lobs_in (p_id IN NUMBER, c_in IN CLOB, b_in IN BLOB)
AS
BEGIN
  INSERT INTO mylobs (id, c, b) VALUES (p_id, c_in, b_in);
END;
/
SHOW ERRORS

-- For lobbinds.js: Procedure to show bind OUT support for LOBs
CREATE OR REPLACE PROCEDURE lobs_out (p_id IN NUMBER, c_out OUT CLOB, b_out OUT BLOB)
AS
BEGIN
  SELECT c, b INTO c_out, b_out FROM mylobs WHERE id = p_id;
END;
/
SHOW ERRORS

-- For lobbinds.js: Procedure to show PL/SQL IN OUT bind support for LOBs
CREATE OR REPLACE PROCEDURE lob_in_out (p_id IN NUMBER, c_inout IN OUT CLOB)
AS
BEGIN
  INSERT INTO mylobs (id, c) VALUES (p_id, c_inout);
  SELECT 'New LOB: ' || c INTO c_inout FROM mylobs WHERE id = p_id;
END;
/
SHOW ERRORS

-- For DBMS_OUTPUT example dbmsoutputpipe.js
CREATE OR REPLACE TYPE dorow AS TABLE OF VARCHAR2(32767);
/
SHOW ERRORS

CREATE OR REPLACE FUNCTION mydofetch RETURN dorow PIPELINED IS
line VARCHAR2(32767);
status INTEGER;
BEGIN LOOP
  DBMS_OUTPUT.GET_LINE(line, status);
  EXIT WHEN status = 1;
  PIPE ROW (line);
END LOOP;
END;
/
SHOW ERRORS

-- For raw1.js
BEGIN EXECUTE IMMEDIATE 'DROP TABLE myraw'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/
CREATE TABLE myraw (r RAW(64));

-- For the executemany*.js examples

BEGIN EXECUTE IMMEDIATE 'DROP TABLE em_tab'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE em_childtab'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE em_parenttab'; EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF; END;
/

CREATE TABLE em_tab (
    id  NUMBER NOT NULL,
    val VARCHAR2(20)
);

CREATE TABLE em_parenttab (
    parentid    NUMBER NOT NULL,
    description VARCHAR2(60) NOT NULL,
    CONSTRAINT parenttab_pk PRIMARY KEY (parentid)
);

CREATE TABLE em_childtab (
    childid     NUMBER NOT NULL,
    parentid    NUMBER NOT NULL,
    description VARCHAR2(30) NOT NULL,
    CONSTRAINT em_childtab_pk PRIMARY KEY (childid),
    CONSTRAINT em_childtab_fk FOREIGN KEY (parentid) REFERENCES em_parenttab
);

INSERT INTO em_parenttab VALUES (10, 'Parent 10');
INSERT INTO em_parenttab VALUES (20, 'Parent 20');
INSERT INTO em_parenttab VALUES (30, 'Parent 30');
INSERT INTO em_parenttab VALUES (40, 'Parent 40');
INSERT INTO em_parenttab VALUES (50, 'Parent 50');

INSERT INTO em_childtab VALUES (1001, 10, 'Child 1001 of Parent 10');
INSERT INTO em_childtab VALUES (1002, 20, 'Child 1002 of Parent 20');
INSERT INTO em_childtab VALUES (1003, 20, 'Child 1003 of Parent 20');
INSERT INTO em_childtab VALUES (1004, 20, 'Child 1004 of Parent 20');
INSERT INTO em_childtab VALUES (1005, 30, 'Child 1005 of Parent 30');
INSERT INTO em_childtab VALUES (1006, 30, 'Child 1006 of Parent 30');
INSERT INTO em_childtab VALUES (1007, 40, 'Child 1007 of Parent 40');
INSERT INTO em_childtab VALUES (1008, 40, 'Child 1008 of Parent 40');
INSERT INTO em_childtab VALUES (1009, 40, 'Child 1009 of Parent 40');
INSERT INTO em_childtab VALUES (1010, 40, 'Child 1010 of Parent 40');
INSERT INTO em_childtab VALUES (1011, 40, 'Child 1011 of Parent 40');
INSERT INTO em_childtab VALUES (1012, 50, 'Child 1012 of Parent 50');
INSERT INTO em_childtab VALUES (1013, 50, 'Child 1013 of Parent 50');
INSERT INTO em_childtab VALUES (1014, 50, 'Child 1014 of Parent 50');
INSERT INTO em_childtab VALUES (1015, 50, 'Child 1015 of Parent 50');

CREATE OR REPLACE PROCEDURE em_testproc (
  a_num IN NUMBER,
  a_outnum OUT NUMBER,
  a_outstr OUT VARCHAR2)
AS
BEGIN
  a_outnum := a_num * 2;
  FOR i IN 1..a_num LOOP
    a_outstr := a_outstr || 'X';
  END LOOP;
END;
/

COMMIT;


-- For the cqn*.js examples

-- The DBA must grant access:
-- GRANT CHANGE NOTIFICATION TO myuser;

create table cqntable (k number);
