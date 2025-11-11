--------------------------------------------------------------------------------
-- DEMO SCRIPT: Exploring Data Redaction Enhancements in Oracle Database 23ai
-- Requirements:
--   (1) Oracle Database 23ai 23.6+
--   (2) HR sample schema installed from https://github.com/oracle-samples/db-sample-schemas/releases
--   (3) Privileges to run DBMS_REDACT and alter HR objects (or run as HR)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 0. Verify setup
--------------------------------------------------------------------------------
SET SERVEROUTPUT ON;

DECLARE
    v_count   NUMBER;
    v_version NUMBER;
BEGIN
    -- Check HR schema
    SELECT COUNT(*) INTO v_count FROM all_users WHERE username = 'HR';
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERROR: HR schema not found. Exiting.');
    END IF;

    -- Check DB version >= 23
    SELECT TO_NUMBER(REGEXP_SUBSTR(version, '^[0-9]+')) INTO v_version FROM v$instance;
    IF v_version < 23 THEN
        RAISE_APPLICATION_ERROR(-20002, 'ERROR: Requires DB version 23 or higher. Exiting.');
    END IF;
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- 1. Create a basic redaction policy
-- Redact data for all users except HR
--------------------------------------------------------------------------------
BEGIN
  DBMS_REDACT.ADD_POLICY(
    object_schema => 'HR',
    object_name   => 'EMPLOYEES',
    policy_name   => 'REDACT_DATA',
    expression    => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') != ''HR'''
  );
END;
/
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- 2. Mathematical and set operators
-- Alter redaction policy to include SALARY column for full redaction
--------------------------------------------------------------------------------
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'HR',
    object_name   => 'EMPLOYEES',
    policy_name   => 'REDACT_DATA',
    column_name   => 'SALARY',
    action        => DBMS_REDACT.ADD_COLUMN,
    function_type => DBMS_REDACT.FULL
  );
END;
/
--------------------------------------------------------------------------------

-- Query employee statistics
SELECT department_id AS dept_id,
       COUNT(employee_id) AS emp_count,
       AVG(salary) AS avg_salary
FROM   hr.employees
GROUP BY department_id
FETCH FIRST 5 ROWS ONLY;
--------------------------------------------------------------------------------
-- HR user sees real values; non-HR sees 0 for avg_salary
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- 3. Redaction with GROUP BY and ORDER BY
--------------------------------------------------------------------------------
SELECT manager_id,
       COUNT(DISTINCT employee_id) AS direct_reports,
       SUM(salary) AS total_team_salary
FROM   hr.employees
GROUP BY manager_id
ORDER BY total_team_salary DESC
FETCH FIRST 5 ROWS ONLY;
--------------------------------------------------------------------------------
-- HR sees totals; non-HR sees 0 (rows may order differently)
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- 4. Redacting virtual columns in function-based indexes
--------------------------------------------------------------------------------

-- Step 1: Create a function-based index (removes periods and hyphens)
CREATE INDEX hr.phone_number_idx
  ON hr.employees(
    REPLACE(REPLACE(phone_number, '.', ''), '-', '')
  );

-- Step 2: Add a virtual column for rounded salary
ALTER TABLE hr.employees ADD (
  rounded_salary AS (ROUND(salary, -3))
);

-- Step 3: Apply redaction to PHONE_NUMBER
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'HR',
    object_name   => 'EMPLOYEES',
    column_name   => 'PHONE_NUMBER',
    policy_name   => 'REDACT_DATA',
    action        => DBMS_REDACT.ADD_COLUMN,
    function_type => DBMS_REDACT.FULL
  );
END;
/

-- Step 4: Update default redaction values
BEGIN
  DBMS_REDACT.UPDATE_FULL_REDACTION_VALUES(
    number_value => 0,
    char_value   => 'X'
  );
END;
/

-- Step 5: Query redacted virtual columns
SELECT employee_id, phone_number, rounded_salary
FROM   hr.employees
WHERE  employee_id IN (101, 103, 176, 201);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- 5. Redaction in Views with Expressions
--------------------------------------------------------------------------------

-- Step 1: Define a view
CREATE OR REPLACE VIEW hr.employee_view AS
  SELECT employee_id AS EMP_ID,
         ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)/12) AS YEARS_OF_SERVICE,
         CONCAT(UPPER(first_name), ' ', UPPER(last_name)) AS FULL_NAME,
         EMAIL
  FROM hr.employees;

-- Step 2: Apply redaction to FIRST_NAME
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'HR',
    object_name   => 'EMPLOYEES',
    policy_name   => 'REDACT_DATA',
    column_name   => 'FIRST_NAME',
    action        => DBMS_REDACT.ADD_COLUMN,
    function_type => DBMS_REDACT.FULL
  );
END;
/

-- Step 3: Apply redaction to EMAIL using regexp
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'HR',
    object_name   => 'EMPLOYEES',
    policy_name   => 'REDACT_DATA',
    column_name   => 'EMAIL',
    action        => DBMS_REDACT.ADD_COLUMN,
    function_type => DBMS_REDACT.REGEXP,
    regexp_pattern         => '^.*$',
    regexp_replace_string  => 'xxxx@company.com',
    regexp_position        => 1,
    regexp_occurrence      => 1,
    regexp_match_parameter => 'i'
  );
END;
/

-- Step 4: Query the view
SELECT emp_id, years_of_service, full_name, email
FROM   hr.employee_view
WHERE  emp_id IN (101, 103, 176, 201);
--------------------------------------------------------------------------------
-- HR sees names/emails; non-HR sees X and xxxx@company.com
--------------------------------------------------------------------------------
