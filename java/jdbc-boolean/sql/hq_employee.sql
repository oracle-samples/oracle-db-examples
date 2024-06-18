CREATE TABLE HQ_EMPLOYEE
(
  "EMP_ID"   NUMBER NOT NULL ENABLE,
  "NAME"    VARCHAR2(20 BYTE) DEFAULT NULL,
  "ROLE"    VARCHAR2(20 BYTE) DEFAULT NULL,
  "ACTIVE" BOOLEAN DEFAULT NULL,
  PRIMARY KEY ("EMP_ID")
);
COMMIT;

DESCRIBE HQ_EMPLOYEE;

-- BOOLEAN = TRUE OR FALSE
INSERT INTO HQ_EMPLOYEE (emp_id, name, role, active) VALUES (1, 'Juarez', 'Developer Evangelist', TRUE); 
INSERT INTO HQ_EMPLOYEE (emp_id, name, role, active) VALUES (2, 'David', 'DevOps Architect', FALSE); 
-- BOOLEAN = 1 OR 0
INSERT INTO HQ_EMPLOYEE (emp_id, name, role, active) VALUES (3, 'Karl', 'Product Manager', 1); 
INSERT INTO HQ_EMPLOYEE (emp_id, name, role, active) VALUES (4, 'Patrick', 'Software Architect', 0);
-- BOOLEAN = 'Y' OR 'N'
INSERT INTO HQ_EMPLOYEE (emp_id, name, role, active) VALUES (5, 'Robert', 'Software Engineer', 'Y');
INSERT INTO HQ_EMPLOYEE (emp_id, name, role, active) VALUES (6, 'James', 'Program Manager', 'N');
COMMIT;