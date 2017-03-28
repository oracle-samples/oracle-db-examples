REM
REM Create the EMPLOYEES table of JSON documents
REM 
DROP TABLE employees PURGE;

CREATE TABLE employees (
  id    RAW(16) NOT NULL,
  data  CLOB,
  CONSTRAINT employees_pk PRIMARY KEY (id),
  CONSTRAINT employees_json_chk CHECK (data IS JSON)
);

TRUNCATE TABLE employees;

INSERT INTO employees (id, data)
VALUES (SYS_GUID(),
        '{
          "EmpId"     : "100",
          "FirstName" : "Kuassi",
          "LastName"  : "Mensah",
          "Job"       : "Manager",
          "Email"     : "kuassi@oracle.com",
          "Address"   : {
                          "City" : "Redwood",
                          "Country" : "US"
                        }
         }');
INSERT INTO employees (id, data)
VALUES (SYS_GUID(),
        '{
          "EmpId"     : "200",
          "FirstName" : "Nancy",
          "LastName"  : "Greenberg",
          "Job"       : "Manager",
          "Email"     : "Nancy@oracle.com",
          "Address"   : {
                          "City" : "Boston",
                          "Country" : "US"
                        }
         }');
INSERT INTO employees (id, data)
VALUES (SYS_GUID(),
        '{
          "EmpId"     : "300",
          "FirstName" : "Suresh",
          "LastName"  : "Mohan",
          "Job"       : "Developer",
          "Email"     : "Suresh@oracle.com",
          "Address"   : {
                          "City" : "Bangalore",
                          "Country" : "India"
                        }
         }');

INSERT INTO employees (id, data)
VALUES (SYS_GUID(),
        '{
          "EmpId"     : "400",
          "FirstName" : "Nirmala",
          "LastName"  : "Sundarappa",
          "Job"       : "Manager",
          "Email"     : "Nirmala@oracle.com",
          "Address"   : {
                          "City" : "Redwood",
                          "Country" : "US"
                        }
         }');

INSERT INTO employees (id, data)
VALUES (SYS_GUID(),
        '{
          "EmpId"     : "500",
          "FirstName" : "Amarnath",
          "LastName"  : "Chandana",
          "Job"       : "Test Devloper",
          "Email"     : "amarnath@oracle.com",
          "Address"   : {
                         "City" : "Bangalore",
                         "Country" : "India"
                        }
         }');
COMMIT;

