# Demo: Exploring Data Redaction Enhancements in Oracle Database 23ai

This demo script showcases new **Oracle Data Redaction** capabilities in Oracle Database 23ai (23.6+).  
It walks through creating and altering redaction policies, applying them to tables, virtual columns, indexes, and views, and observing how results differ for **HR** versus non-HR users.

## Requirements

- **Oracle Database 23ai 23.6+**  
- **HR sample schema** installed from [Oracle Sample Schemas](https://github.com/oracle-samples/db-sample-schemas/releases)  
- Privileges to run `DBMS_REDACT` and alter objects in the HR schema (recommended: run as HR)


## Script Sections

### 0. Verify Setup
- Confirms **HR schema** exists  
- Confirms **Database version ≥ 23**  
- Script exits if either requirement is not met  

### 1. Basic Redaction Policy
- Creates a policy on `HR.EMPLOYEES`  
- Redacts data for all users except HR  

### 2. Mathematical and Set Operators
- Adds redaction to the `SALARY` column  
- Demonstrates impact on `GROUP BY` queries (e.g., average salary)  

### 3. Redaction with GROUP BY and ORDER BY
- Queries team statistics by manager  
- Shows difference in totals/order for HR vs non-HR users  

### 4. Redacting Virtual Columns & Function-Based Indexes
- Creates a function-based index on `PHONE_NUMBER`  
- Adds a virtual column (`ROUNDED_SALARY`)  
- Applies redaction to `PHONE_NUMBER`  
- Updates default redaction values (e.g., numbers -> 0, chars -> X)  
- Queries redacted results  

### 5. Redaction in Views with Expressions
- Creates a view `HR.EMPLOYEE_VIEW` with calculated columns  
- Redacts `FIRST_NAME` (full)  
- Redacts `EMAIL` using **regular expression replacement**  
- Queries the view to illustrate differences for HR vs non-HR users  

---

## How to Run
1. Connect as a user with privileges (e.g., `HR`) in **SQL*Plus** or **SQL Developer**  
2. Execute the script


## To learn more about Oracle Data Redaction:
- Visit the Advanced Security product page (https://www.oracle.com/security/database-security/advanced-security/#redact-data) on the Oracle website. 
- For hands-on experience, try our free, interactive Oracle Data Redaction LiveLab (https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/view-workshop?wid=4061&clear=RR,180&session=1856055320747). 

