CREATE USER BOT_USER IDENTIFIED BY <YOUR_PASSWORD> QUOTA UNLIMITED ON USERS;
GRANT DB_DEVELOPER_ROLE TO BOT_USER;
GRANT CREATE SESSION TO BOT_USER;
GRANT SELECT ANY TABLE ON SCHEMA BOT_USER TO BOT_USER;
GRANT INSERT ANY TABLE ON SCHEMA BOT_USER TO BOT_USER;
GRANT UPDATE ANY TABLE ON SCHEMA BOT_USER TO BOT_USER;
GRANT DELETE ANY TABLE ON SCHEMA BOT_USER TO BOT_USER;
ALTER SESSION SET CURRENT_SCHEMA = BOT_USER;

CREATE TABLE Healthy
(id NUMBER(10) CONSTRAINT pk_healthy PRIMARY KEY,
tip VARCHAR2(70));
   
INSERT INTO Healthy VALUES(1,'Small changes can make a big difference. Start TODAY!');
INSERT INTO Healthy VALUES(2,'Base your meals on higher fibre starchy carbohydrates');
INSERT INTO Healthy VALUES(3,'Eat lots of fruit and vegetables');
INSERT INTO Healthy VALUES(4,'Eat more fish, including a portion of oily fish');
INSERT INTO Healthy VALUES(5,'Cut down on saturated fat and sugar');
INSERT INTO Healthy VALUES(6,'Eat less salt: no more than 6g a day for adults');
INSERT INTO Healthy VALUES(7,'Get active and be a healthy weight');
INSERT INTO Healthy VALUES(8,'Do not get thirsty');
INSERT INTO Healthy VALUES(9,'Do not skip breakfast');
INSERT INTO Healthy VALUES(10,'Eat more vegetables, salad and fruit - Up to seven servings a day');
INSERT INTO Healthy VALUES(11,'Limit intake of high fat, sugar, salt (HFSS) food and drinks ');
INSERT INTO Healthy VALUES(12,'Size matters: Use the food pyramid as a guide for serving sizes');
INSERT INTO Healthy VALUES(13,'Increase your physical activity levels');

COMMIT;