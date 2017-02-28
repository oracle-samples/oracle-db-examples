create or replace directory tpcsd_load_dir as '/tmp/tpcdsload';                 
------------------------------------------------------------------------------- 
drop table X_CALL_CENTER;                                                       
create table X_CALL_CENTER (                                                    
CC_CALL_CENTER_SK NUMBER(38)                                                    
,CC_CALL_CENTER_ID CHAR(16)                                                     
,CC_REC_START_DATE DATE                                                         
,CC_REC_END_DATE DATE                                                           
,CC_CLOSED_DATE_SK NUMBER(38)                                                   
,CC_OPEN_DATE_SK NUMBER(38)                                                     
,CC_NAME VARCHAR2(50)                                                           
,CC_CLASS VARCHAR2(50)                                                          
,CC_EMPLOYEES NUMBER(38)                                                        
,CC_SQ_FT NUMBER(38)                                                            
,CC_HOURS CHAR(20)                                                              
,CC_MANAGER VARCHAR2(40)                                                        
,CC_MKT_ID NUMBER(38)                                                           
,CC_MKT_CLASS CHAR(50)                                                          
,CC_MKT_DESC VARCHAR2(100)                                                      
,CC_MARKET_MANAGER VARCHAR2(40)                                                 
,CC_DIVISION NUMBER(38)                                                         
,CC_DIVISION_NAME VARCHAR2(50)                                                  
,CC_COMPANY NUMBER(38)                                                          
,CC_COMPANY_NAME CHAR(50)                                                       
,CC_STREET_NUMBER CHAR(10)                                                      
,CC_STREET_NAME VARCHAR2(60)                                                    
,CC_STREET_TYPE CHAR(15)                                                        
,CC_SUITE_NUMBER CHAR(10)                                                       
,CC_CITY VARCHAR2(60)                                                           
,CC_COUNTY VARCHAR2(30)                                                         
,CC_STATE CHAR(2)                                                               
,CC_ZIP CHAR(10)                                                                
,CC_COUNTRY VARCHAR2(20)                                                        
,CC_GMT_OFFSET NUMBER(5,2)                                                      
,CC_TAX_PERCENTAGE NUMBER(5,2)                                                  
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
CC_CALL_CENTER_SK                                                               
,CC_CALL_CENTER_ID                                                              
,CC_REC_START_DATE date "YYYY-MM-DD"                                            
,CC_REC_END_DATE date "YYYY-MM-DD"                                              
,CC_CLOSED_DATE_SK                                                              
,CC_OPEN_DATE_SK                                                                
,CC_NAME                                                                        
,CC_CLASS                                                                       
,CC_EMPLOYEES                                                                   
,CC_SQ_FT                                                                       
,CC_HOURS                                                                       
,CC_MANAGER                                                                     
,CC_MKT_ID                                                                      
,CC_MKT_CLASS                                                                   
,CC_MKT_DESC                                                                    
,CC_MARKET_MANAGER                                                              
,CC_DIVISION                                                                    
,CC_DIVISION_NAME                                                               
,CC_COMPANY                                                                     
,CC_COMPANY_NAME                                                                
,CC_STREET_NUMBER                                                               
,CC_STREET_NAME                                                                 
,CC_STREET_TYPE                                                                 
,CC_SUITE_NUMBER                                                                
,CC_CITY                                                                        
,CC_COUNTY                                                                      
,CC_STATE                                                                       
,CC_ZIP                                                                         
,CC_COUNTRY                                                                     
,CC_GMT_OFFSET                                                                  
,CC_TAX_PERCENTAGE                                                              
)) location ('call_center.dat')                                                 
);                                                                              
------------------------------------------------------------------------------- 
drop table X_CATALOG_PAGE;                                                      
create table X_CATALOG_PAGE (                                                   
CP_CATALOG_PAGE_SK NUMBER(38)                                                   
,CP_CATALOG_PAGE_ID CHAR(16)                                                    
,CP_START_DATE_SK NUMBER(38)                                                    
,CP_END_DATE_SK NUMBER(38)                                                      
,CP_DEPARTMENT VARCHAR2(50)                                                     
,CP_CATALOG_NUMBER NUMBER(38)                                                   
,CP_CATALOG_PAGE_NUMBER NUMBER(38)                                              
,CP_DESCRIPTION VARCHAR2(100)                                                   
,CP_TYPE VARCHAR2(100)                                                          
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
CP_CATALOG_PAGE_SK                                                              
,CP_CATALOG_PAGE_ID                                                             
,CP_START_DATE_SK                                                               
,CP_END_DATE_SK                                                                 
,CP_DEPARTMENT                                                                  
,CP_CATALOG_NUMBER                                                              
,CP_CATALOG_PAGE_NUMBER                                                         
,CP_DESCRIPTION                                                                 
,CP_TYPE                                                                        
)) location ('catalog_page.dat')                                                
);                                                                              
------------------------------------------------------------------------------- 
drop table X_CATALOG_RETURNS;                                                   
create table X_CATALOG_RETURNS (                                                
CR_RETURNED_DATE_SK NUMBER(38)                                                  
,CR_RETURNED_TIME_SK NUMBER(38)                                                 
,CR_ITEM_SK NUMBER(38)                                                          
,CR_REFUNDED_CUSTOMER_SK NUMBER(38)                                             
,CR_REFUNDED_CDEMO_SK NUMBER(38)                                                
,CR_REFUNDED_HDEMO_SK NUMBER(38)                                                
,CR_REFUNDED_ADDR_SK NUMBER(38)                                                 
,CR_RETURNING_CUSTOMER_SK NUMBER(38)                                            
,CR_RETURNING_CDEMO_SK NUMBER(38)                                               
,CR_RETURNING_HDEMO_SK NUMBER(38)                                               
,CR_RETURNING_ADDR_SK NUMBER(38)                                                
,CR_CALL_CENTER_SK NUMBER(38)                                                   
,CR_CATALOG_PAGE_SK NUMBER(38)                                                  
,CR_SHIP_MODE_SK NUMBER(38)                                                     
,CR_WAREHOUSE_SK NUMBER(38)                                                     
,CR_REASON_SK NUMBER(38)                                                        
,CR_ORDER_NUMBER NUMBER(38)                                                     
,CR_RETURN_QUANTITY NUMBER(38)                                                  
,CR_RETURN_AMOUNT NUMBER(7,2)                                                   
,CR_RETURN_TAX NUMBER(7,2)                                                      
,CR_RETURN_AMT_INC_TAX NUMBER(7,2)                                              
,CR_FEE NUMBER(7,2)                                                             
,CR_RETURN_SHIP_COST NUMBER(7,2)                                                
,CR_REFUNDED_CASH NUMBER(7,2)                                                   
,CR_REVERSED_CHARGE NUMBER(7,2)                                                 
,CR_STORE_CREDIT NUMBER(7,2)                                                    
,CR_NET_LOSS NUMBER(7,2)                                                        
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
CR_RETURNED_DATE_SK                                                             
,CR_RETURNED_TIME_SK                                                            
,CR_ITEM_SK                                                                     
,CR_REFUNDED_CUSTOMER_SK                                                        
,CR_REFUNDED_CDEMO_SK                                                           
,CR_REFUNDED_HDEMO_SK                                                           
,CR_REFUNDED_ADDR_SK                                                            
,CR_RETURNING_CUSTOMER_SK                                                       
,CR_RETURNING_CDEMO_SK                                                          
,CR_RETURNING_HDEMO_SK                                                          
,CR_RETURNING_ADDR_SK                                                           
,CR_CALL_CENTER_SK                                                              
,CR_CATALOG_PAGE_SK                                                             
,CR_SHIP_MODE_SK                                                                
,CR_WAREHOUSE_SK                                                                
,CR_REASON_SK                                                                   
,CR_ORDER_NUMBER                                                                
,CR_RETURN_QUANTITY                                                             
,CR_RETURN_AMOUNT                                                               
,CR_RETURN_TAX                                                                  
,CR_RETURN_AMT_INC_TAX                                                          
,CR_FEE                                                                         
,CR_RETURN_SHIP_COST                                                            
,CR_REFUNDED_CASH                                                               
,CR_REVERSED_CHARGE                                                             
,CR_STORE_CREDIT                                                                
,CR_NET_LOSS                                                                    
)) location ('catalog_returns.dat')                                             
);                                                                              
------------------------------------------------------------------------------- 
drop table X_CATALOG_SALES;                                                     
create table X_CATALOG_SALES (                                                  
CS_SOLD_DATE_SK NUMBER(38)                                                      
,CS_SOLD_TIME_SK NUMBER(38)                                                     
,CS_SHIP_DATE_SK NUMBER(38)                                                     
,CS_BILL_CUSTOMER_SK NUMBER(38)                                                 
,CS_BILL_CDEMO_SK NUMBER(38)                                                    
,CS_BILL_HDEMO_SK NUMBER(38)                                                    
,CS_BILL_ADDR_SK NUMBER(38)                                                     
,CS_SHIP_CUSTOMER_SK NUMBER(38)                                                 
,CS_SHIP_CDEMO_SK NUMBER(38)                                                    
,CS_SHIP_HDEMO_SK NUMBER(38)                                                    
,CS_SHIP_ADDR_SK NUMBER(38)                                                     
,CS_CALL_CENTER_SK NUMBER(38)                                                   
,CS_CATALOG_PAGE_SK NUMBER(38)                                                  
,CS_SHIP_MODE_SK NUMBER(38)                                                     
,CS_WAREHOUSE_SK NUMBER(38)                                                     
,CS_ITEM_SK NUMBER(38)                                                          
,CS_PROMO_SK NUMBER(38)                                                         
,CS_ORDER_NUMBER NUMBER(38)                                                     
,CS_QUANTITY NUMBER(38)                                                         
,CS_WHOLESALE_COST NUMBER(7,2)                                                  
,CS_LIST_PRICE NUMBER(7,2)                                                      
,CS_SALES_PRICE NUMBER(7,2)                                                     
,CS_EXT_DISCOUNT_AMT NUMBER(7,2)                                                
,CS_EXT_SALES_PRICE NUMBER(7,2)                                                 
,CS_EXT_WHOLESALE_COST NUMBER(7,2)                                              
,CS_EXT_LIST_PRICE NUMBER(7,2)                                                  
,CS_EXT_TAX NUMBER(7,2)                                                         
,CS_COUPON_AMT NUMBER(7,2)                                                      
,CS_EXT_SHIP_COST NUMBER(7,2)                                                   
,CS_NET_PAID NUMBER(7,2)                                                        
,CS_NET_PAID_INC_TAX NUMBER(7,2)                                                
,CS_NET_PAID_INC_SHIP NUMBER(7,2)                                               
,CS_NET_PAID_INC_SHIP_TAX NUMBER(7,2)                                           
,CS_NET_PROFIT NUMBER(7,2)                                                      
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
CS_SOLD_DATE_SK                                                                 
,CS_SOLD_TIME_SK                                                                
,CS_SHIP_DATE_SK                                                                
,CS_BILL_CUSTOMER_SK                                                            
,CS_BILL_CDEMO_SK                                                               
,CS_BILL_HDEMO_SK                                                               
,CS_BILL_ADDR_SK                                                                
,CS_SHIP_CUSTOMER_SK                                                            
,CS_SHIP_CDEMO_SK                                                               
,CS_SHIP_HDEMO_SK                                                               
,CS_SHIP_ADDR_SK                                                                
,CS_CALL_CENTER_SK                                                              
,CS_CATALOG_PAGE_SK                                                             
,CS_SHIP_MODE_SK                                                                
,CS_WAREHOUSE_SK                                                                
,CS_ITEM_SK                                                                     
,CS_PROMO_SK                                                                    
,CS_ORDER_NUMBER                                                                
,CS_QUANTITY                                                                    
,CS_WHOLESALE_COST                                                              
,CS_LIST_PRICE                                                                  
,CS_SALES_PRICE                                                                 
,CS_EXT_DISCOUNT_AMT                                                            
,CS_EXT_SALES_PRICE                                                             
,CS_EXT_WHOLESALE_COST                                                          
,CS_EXT_LIST_PRICE                                                              
,CS_EXT_TAX                                                                     
,CS_COUPON_AMT                                                                  
,CS_EXT_SHIP_COST                                                               
,CS_NET_PAID                                                                    
,CS_NET_PAID_INC_TAX                                                            
,CS_NET_PAID_INC_SHIP                                                           
,CS_NET_PAID_INC_SHIP_TAX                                                       
,CS_NET_PROFIT                                                                  
)) location ('catalog_sales.dat')                                               
);                                                                              
------------------------------------------------------------------------------- 
drop table X_CUSTOMER;                                                          
create table X_CUSTOMER (                                                       
C_CUSTOMER_SK NUMBER(38)                                                        
,C_CUSTOMER_ID CHAR(16)                                                         
,C_CURRENT_CDEMO_SK NUMBER(38)                                                  
,C_CURRENT_HDEMO_SK NUMBER(38)                                                  
,C_CURRENT_ADDR_SK NUMBER(38)                                                   
,C_FIRST_SHIPTO_DATE_SK NUMBER(38)                                              
,C_FIRST_SALES_DATE_SK NUMBER(38)                                               
,C_SALUTATION CHAR(10)                                                          
,C_FIRST_NAME CHAR(20)                                                          
,C_LAST_NAME CHAR(30)                                                           
,C_PREFERRED_CUST_FLAG CHAR(1)                                                  
,C_BIRTH_DAY NUMBER(38)                                                         
,C_BIRTH_MONTH NUMBER(38)                                                       
,C_BIRTH_YEAR NUMBER(38)                                                        
,C_BIRTH_COUNTRY VARCHAR2(20)                                                   
,C_LOGIN CHAR(13)                                                               
,C_EMAIL_ADDRESS CHAR(50)                                                       
,C_LAST_REVIEW_DATE CHAR(10)                                                    
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
C_CUSTOMER_SK                                                                   
,C_CUSTOMER_ID                                                                  
,C_CURRENT_CDEMO_SK                                                             
,C_CURRENT_HDEMO_SK                                                             
,C_CURRENT_ADDR_SK                                                              
,C_FIRST_SHIPTO_DATE_SK                                                         
,C_FIRST_SALES_DATE_SK                                                          
,C_SALUTATION                                                                   
,C_FIRST_NAME                                                                   
,C_LAST_NAME                                                                    
,C_PREFERRED_CUST_FLAG                                                          
,C_BIRTH_DAY                                                                    
,C_BIRTH_MONTH                                                                  
,C_BIRTH_YEAR                                                                   
,C_BIRTH_COUNTRY                                                                
,C_LOGIN                                                                        
,C_EMAIL_ADDRESS                                                                
,C_LAST_REVIEW_DATE                                                             
)) location ('customer.dat')                                                    
);                                                                              
------------------------------------------------------------------------------- 
drop table X_CUSTOMER_ADDRESS;                                                  
create table X_CUSTOMER_ADDRESS (                                               
CA_ADDRESS_SK NUMBER(38)                                                        
,CA_ADDRESS_ID CHAR(16)                                                         
,CA_STREET_NUMBER CHAR(10)                                                      
,CA_STREET_NAME VARCHAR2(60)                                                    
,CA_STREET_TYPE CHAR(15)                                                        
,CA_SUITE_NUMBER CHAR(10)                                                       
,CA_CITY VARCHAR2(60)                                                           
,CA_COUNTY VARCHAR2(30)                                                         
,CA_STATE CHAR(2)                                                               
,CA_ZIP CHAR(10)                                                                
,CA_COUNTRY VARCHAR2(20)                                                        
,CA_GMT_OFFSET NUMBER(5,2)                                                      
,CA_LOCATION_TYPE CHAR(20)                                                      
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
CA_ADDRESS_SK                                                                   
,CA_ADDRESS_ID                                                                  
,CA_STREET_NUMBER                                                               
,CA_STREET_NAME                                                                 
,CA_STREET_TYPE                                                                 
,CA_SUITE_NUMBER                                                                
,CA_CITY                                                                        
,CA_COUNTY                                                                      
,CA_STATE                                                                       
,CA_ZIP                                                                         
,CA_COUNTRY                                                                     
,CA_GMT_OFFSET                                                                  
,CA_LOCATION_TYPE                                                               
)) location ('customer_address.dat')                                            
);                                                                              
------------------------------------------------------------------------------- 
drop table X_CUSTOMER_DEMOGRAPHICS;                                             
create table X_CUSTOMER_DEMOGRAPHICS (                                          
CD_DEMO_SK NUMBER(38)                                                           
,CD_GENDER CHAR(1)                                                              
,CD_MARITAL_STATUS CHAR(1)                                                      
,CD_EDUCATION_STATUS CHAR(20)                                                   
,CD_PURCHASE_ESTIMATE NUMBER(38)                                                
,CD_CREDIT_RATING CHAR(10)                                                      
,CD_DEP_COUNT NUMBER(38)                                                        
,CD_DEP_EMPLOYED_COUNT NUMBER(38)                                               
,CD_DEP_COLLEGE_COUNT NUMBER(38)                                                
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
CD_DEMO_SK                                                                      
,CD_GENDER                                                                      
,CD_MARITAL_STATUS                                                              
,CD_EDUCATION_STATUS                                                            
,CD_PURCHASE_ESTIMATE                                                           
,CD_CREDIT_RATING                                                               
,CD_DEP_COUNT                                                                   
,CD_DEP_EMPLOYED_COUNT                                                          
,CD_DEP_COLLEGE_COUNT                                                           
)) location ('customer_demographics.dat')                                       
);                                                                              
------------------------------------------------------------------------------- 
drop table X_DATE_DIM;                                                          
create table X_DATE_DIM (                                                       
D_DATE_SK NUMBER(38)                                                            
,D_DATE_ID CHAR(16)                                                             
,D_DATE DATE                                                                    
,D_MONTH_SEQ NUMBER(38)                                                         
,D_WEEK_SEQ NUMBER(38)                                                          
,D_QUARTER_SEQ NUMBER(38)                                                       
,D_YEAR NUMBER(38)                                                              
,D_DOW NUMBER(38)                                                               
,D_MOY NUMBER(38)                                                               
,D_DOM NUMBER(38)                                                               
,D_QOY NUMBER(38)                                                               
,D_FY_YEAR NUMBER(38)                                                           
,D_FY_QUARTER_SEQ NUMBER(38)                                                    
,D_FY_WEEK_SEQ NUMBER(38)                                                       
,D_DAY_NAME CHAR(9)                                                             
,D_QUARTER_NAME CHAR(6)                                                         
,D_HOLIDAY CHAR(1)                                                              
,D_WEEKEND CHAR(1)                                                              
,D_FOLLOWING_HOLIDAY CHAR(1)                                                    
,D_FIRST_DOM NUMBER(38)                                                         
,D_LAST_DOM NUMBER(38)                                                          
,D_SAME_DAY_LY NUMBER(38)                                                       
,D_SAME_DAY_LQ NUMBER(38)                                                       
,D_CURRENT_DAY CHAR(1)                                                          
,D_CURRENT_WEEK CHAR(1)                                                         
,D_CURRENT_MONTH CHAR(1)                                                        
,D_CURRENT_QUARTER CHAR(1)                                                      
,D_CURRENT_YEAR CHAR(1)                                                         
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
D_DATE_SK                                                                       
,D_DATE_ID                                                                      
,D_DATE date "YYYY-MM-DD"                                                       
,D_MONTH_SEQ                                                                    
,D_WEEK_SEQ                                                                     
,D_QUARTER_SEQ                                                                  
,D_YEAR                                                                         
,D_DOW                                                                          
,D_MOY                                                                          
,D_DOM                                                                          
,D_QOY                                                                          
,D_FY_YEAR                                                                      
,D_FY_QUARTER_SEQ                                                               
,D_FY_WEEK_SEQ                                                                  
,D_DAY_NAME                                                                     
,D_QUARTER_NAME                                                                 
,D_HOLIDAY                                                                      
,D_WEEKEND                                                                      
,D_FOLLOWING_HOLIDAY                                                            
,D_FIRST_DOM                                                                    
,D_LAST_DOM                                                                     
,D_SAME_DAY_LY                                                                  
,D_SAME_DAY_LQ                                                                  
,D_CURRENT_DAY                                                                  
,D_CURRENT_WEEK                                                                 
,D_CURRENT_MONTH                                                                
,D_CURRENT_QUARTER                                                              
,D_CURRENT_YEAR                                                                 
)) location ('date_dim.dat')                                                    
);                                                                              
------------------------------------------------------------------------------- 
drop table X_HOUSEHOLD_DEMOGRAPHICS;                                            
create table X_HOUSEHOLD_DEMOGRAPHICS (                                         
HD_DEMO_SK NUMBER(38)                                                           
,HD_INCOME_BAND_SK NUMBER(38)                                                   
,HD_BUY_POTENTIAL CHAR(15)                                                      
,HD_DEP_COUNT NUMBER(38)                                                        
,HD_VEHICLE_COUNT NUMBER(38)                                                    
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
HD_DEMO_SK                                                                      
,HD_INCOME_BAND_SK                                                              
,HD_BUY_POTENTIAL                                                               
,HD_DEP_COUNT                                                                   
,HD_VEHICLE_COUNT                                                               
)) location ('household_demographics.dat')                                      
);                                                                              
------------------------------------------------------------------------------- 
drop table X_INCOME_BAND;                                                       
create table X_INCOME_BAND (                                                    
IB_INCOME_BAND_SK NUMBER(38)                                                    
,IB_LOWER_BOUND NUMBER(38)                                                      
,IB_UPPER_BOUND NUMBER(38)                                                      
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
IB_INCOME_BAND_SK                                                               
,IB_LOWER_BOUND                                                                 
,IB_UPPER_BOUND                                                                 
)) location ('income_band.dat')                                                 
);                                                                              
------------------------------------------------------------------------------- 
drop table X_INVENTORY;                                                         
create table X_INVENTORY (                                                      
INV_DATE_SK NUMBER(38)                                                          
,INV_ITEM_SK NUMBER(38)                                                         
,INV_WAREHOUSE_SK NUMBER(38)                                                    
,INV_QUANTITY_ON_HAND NUMBER(38)                                                
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
INV_DATE_SK                                                                     
,INV_ITEM_SK                                                                    
,INV_WAREHOUSE_SK                                                               
,INV_QUANTITY_ON_HAND                                                           
)) location ('inventory.dat')                                                   
);                                                                              
------------------------------------------------------------------------------- 
drop table X_ITEM;                                                              
create table X_ITEM (                                                           
I_ITEM_SK NUMBER(38)                                                            
,I_ITEM_ID CHAR(16)                                                             
,I_REC_START_DATE DATE                                                          
,I_REC_END_DATE DATE                                                            
,I_ITEM_DESC VARCHAR2(200)                                                      
,I_CURRENT_PRICE NUMBER(7,2)                                                    
,I_WHOLESALE_COST NUMBER(7,2)                                                   
,I_BRAND_ID NUMBER(38)                                                          
,I_BRAND CHAR(50)                                                               
,I_CLASS_ID NUMBER(38)                                                          
,I_CLASS CHAR(50)                                                               
,I_CATEGORY_ID NUMBER(38)                                                       
,I_CATEGORY CHAR(50)                                                            
,I_MANUFACT_ID NUMBER(38)                                                       
,I_MANUFACT CHAR(50)                                                            
,I_SIZE CHAR(20)                                                                
,I_FORMULATION CHAR(20)                                                         
,I_COLOR CHAR(20)                                                               
,I_UNITS CHAR(10)                                                               
,I_CONTAINER CHAR(10)                                                           
,I_MANAGER_ID NUMBER(38)                                                        
,I_PRODUCT_NAME CHAR(50)                                                        
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
I_ITEM_SK                                                                       
,I_ITEM_ID                                                                      
,I_REC_START_DATE date "YYYY-MM-DD"                                             
,I_REC_END_DATE date "YYYY-MM-DD"                                               
,I_ITEM_DESC                                                                    
,I_CURRENT_PRICE                                                                
,I_WHOLESALE_COST                                                               
,I_BRAND_ID                                                                     
,I_BRAND                                                                        
,I_CLASS_ID                                                                     
,I_CLASS                                                                        
,I_CATEGORY_ID                                                                  
,I_CATEGORY                                                                     
,I_MANUFACT_ID                                                                  
,I_MANUFACT                                                                     
,I_SIZE                                                                         
,I_FORMULATION                                                                  
,I_COLOR                                                                        
,I_UNITS                                                                        
,I_CONTAINER                                                                    
,I_MANAGER_ID                                                                   
,I_PRODUCT_NAME                                                                 
)) location ('item.dat')                                                        
);                                                                              
------------------------------------------------------------------------------- 
drop table X_PROMOTION;                                                         
create table X_PROMOTION (                                                      
P_PROMO_SK NUMBER(38)                                                           
,P_PROMO_ID CHAR(16)                                                            
,P_START_DATE_SK NUMBER(38)                                                     
,P_END_DATE_SK NUMBER(38)                                                       
,P_ITEM_SK NUMBER(38)                                                           
,P_COST NUMBER(15,2)                                                            
,P_RESPONSE_TARGET NUMBER(38)                                                   
,P_PROMO_NAME CHAR(50)                                                          
,P_CHANNEL_DMAIL CHAR(1)                                                        
,P_CHANNEL_EMAIL CHAR(1)                                                        
,P_CHANNEL_CATALOG CHAR(1)                                                      
,P_CHANNEL_TV CHAR(1)                                                           
,P_CHANNEL_RADIO CHAR(1)                                                        
,P_CHANNEL_PRESS CHAR(1)                                                        
,P_CHANNEL_EVENT CHAR(1)                                                        
,P_CHANNEL_DEMO CHAR(1)                                                         
,P_CHANNEL_DETAILS VARCHAR2(100)                                                
,P_PURPOSE CHAR(15)                                                             
,P_DISCOUNT_ACTIVE CHAR(1)                                                      
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
P_PROMO_SK                                                                      
,P_PROMO_ID                                                                     
,P_START_DATE_SK                                                                
,P_END_DATE_SK                                                                  
,P_ITEM_SK                                                                      
,P_COST                                                                         
,P_RESPONSE_TARGET                                                              
,P_PROMO_NAME                                                                   
,P_CHANNEL_DMAIL                                                                
,P_CHANNEL_EMAIL                                                                
,P_CHANNEL_CATALOG                                                              
,P_CHANNEL_TV                                                                   
,P_CHANNEL_RADIO                                                                
,P_CHANNEL_PRESS                                                                
,P_CHANNEL_EVENT                                                                
,P_CHANNEL_DEMO                                                                 
,P_CHANNEL_DETAILS                                                              
,P_PURPOSE                                                                      
,P_DISCOUNT_ACTIVE                                                              
)) location ('promotion.dat')                                                   
);                                                                              
------------------------------------------------------------------------------- 
drop table X_REASON;                                                            
create table X_REASON (                                                         
R_REASON_SK NUMBER(38)                                                          
,R_REASON_ID CHAR(16)                                                           
,R_REASON_DESC CHAR(100)                                                        
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
R_REASON_SK                                                                     
,R_REASON_ID                                                                    
,R_REASON_DESC                                                                  
)) location ('reason.dat')                                                      
);                                                                              
------------------------------------------------------------------------------- 
drop table X_TIME_DIM;                                                          
create table X_TIME_DIM (                                                       
T_TIME_SK NUMBER(38)                                                            
,T_TIME_ID CHAR(16)                                                             
,T_TIME NUMBER(38)                                                              
,T_HOUR NUMBER(38)                                                              
,T_MINUTE NUMBER(38)                                                            
,T_SECOND NUMBER(38)                                                            
,T_AM_PM CHAR(2)                                                                
,T_SHIFT CHAR(20)                                                               
,T_SUB_SHIFT CHAR(20)                                                           
,T_MEAL_TIME CHAR(20)                                                           
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
T_TIME_SK                                                                       
,T_TIME_ID                                                                      
,T_TIME                                                                         
,T_HOUR                                                                         
,T_MINUTE                                                                       
,T_SECOND                                                                       
,T_AM_PM                                                                        
,T_SHIFT                                                                        
,T_SUB_SHIFT                                                                    
,T_MEAL_TIME                                                                    
)) location ('time_dim.dat')                                                    
);                                                                              
------------------------------------------------------------------------------- 
drop table X_TPCDS_FILE_LOOKUP;                                                 
create table X_TPCDS_FILE_LOOKUP (                                              
TNAME VARCHAR2(100)                                                             
,FNAME VARCHAR2(500)                                                            
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
TNAME                                                                           
,FNAME                                                                          
)) location ('tpcds_file_lookup.dat')                                           
);                                                                              
------------------------------------------------------------------------------- 
drop table X_WAREHOUSE;                                                         
create table X_WAREHOUSE (                                                      
W_WAREHOUSE_SK NUMBER(38)                                                       
,W_WAREHOUSE_ID CHAR(16)                                                        
,W_WAREHOUSE_NAME VARCHAR2(20)                                                  
,W_WAREHOUSE_SQ_FT NUMBER(38)                                                   
,W_STREET_NUMBER CHAR(10)                                                       
,W_STREET_NAME VARCHAR2(60)                                                     
,W_STREET_TYPE CHAR(15)                                                         
,W_SUITE_NUMBER CHAR(10)                                                        
,W_CITY VARCHAR2(60)                                                            
,W_COUNTY VARCHAR2(30)                                                          
,W_STATE CHAR(2)                                                                
,W_ZIP CHAR(10)                                                                 
,W_COUNTRY VARCHAR2(20)                                                         
,W_GMT_OFFSET NUMBER(5,2)                                                       
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
W_WAREHOUSE_SK                                                                  
,W_WAREHOUSE_ID                                                                 
,W_WAREHOUSE_NAME                                                               
,W_WAREHOUSE_SQ_FT                                                              
,W_STREET_NUMBER                                                                
,W_STREET_NAME                                                                  
,W_STREET_TYPE                                                                  
,W_SUITE_NUMBER                                                                 
,W_CITY                                                                         
,W_COUNTY                                                                       
,W_STATE                                                                        
,W_ZIP                                                                          
,W_COUNTRY                                                                      
,W_GMT_OFFSET                                                                   
)) location ('warehouse.dat')                                                   
);                                                                              
------------------------------------------------------------------------------- 
drop table X_WEB_PAGE;                                                          
create table X_WEB_PAGE (                                                       
WP_WEB_PAGE_SK NUMBER(38)                                                       
,WP_WEB_PAGE_ID CHAR(16)                                                        
,WP_REC_START_DATE DATE                                                         
,WP_REC_END_DATE DATE                                                           
,WP_CREATION_DATE_SK NUMBER(38)                                                 
,WP_ACCESS_DATE_SK NUMBER(38)                                                   
,WP_AUTOGEN_FLAG CHAR(1)                                                        
,WP_CUSTOMER_SK NUMBER(38)                                                      
,WP_URL VARCHAR2(100)                                                           
,WP_TYPE CHAR(50)                                                               
,WP_CHAR_COUNT NUMBER(38)                                                       
,WP_LINK_COUNT NUMBER(38)                                                       
,WP_IMAGE_COUNT NUMBER(38)                                                      
,WP_MAX_AD_COUNT NUMBER(38)                                                     
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
WP_WEB_PAGE_SK                                                                  
,WP_WEB_PAGE_ID                                                                 
,WP_REC_START_DATE date "YYYY-MM-DD"                                            
,WP_REC_END_DATE date "YYYY-MM-DD"                                              
,WP_CREATION_DATE_SK                                                            
,WP_ACCESS_DATE_SK                                                              
,WP_AUTOGEN_FLAG                                                                
,WP_CUSTOMER_SK                                                                 
,WP_URL                                                                         
,WP_TYPE                                                                        
,WP_CHAR_COUNT                                                                  
,WP_LINK_COUNT                                                                  
,WP_IMAGE_COUNT                                                                 
,WP_MAX_AD_COUNT                                                                
)) location ('web_page.dat')                                                    
);                                                                              
------------------------------------------------------------------------------- 
drop table X_WEB_RETURNS;                                                       
create table X_WEB_RETURNS (                                                    
WR_RETURNED_DATE_SK NUMBER(38)                                                  
,WR_RETURNED_TIME_SK NUMBER(38)                                                 
,WR_ITEM_SK NUMBER(38)                                                          
,WR_REFUNDED_CUSTOMER_SK NUMBER(38)                                             
,WR_REFUNDED_CDEMO_SK NUMBER(38)                                                
,WR_REFUNDED_HDEMO_SK NUMBER(38)                                                
,WR_REFUNDED_ADDR_SK NUMBER(38)                                                 
,WR_RETURNING_CUSTOMER_SK NUMBER(38)                                            
,WR_RETURNING_CDEMO_SK NUMBER(38)                                               
,WR_RETURNING_HDEMO_SK NUMBER(38)                                               
,WR_RETURNING_ADDR_SK NUMBER(38)                                                
,WR_WEB_PAGE_SK NUMBER(38)                                                      
,WR_REASON_SK NUMBER(38)                                                        
,WR_ORDER_NUMBER NUMBER(38)                                                     
,WR_RETURN_QUANTITY NUMBER(38)                                                  
,WR_RETURN_AMT NUMBER(7,2)                                                      
,WR_RETURN_TAX NUMBER(7,2)                                                      
,WR_RETURN_AMT_INC_TAX NUMBER(7,2)                                              
,WR_FEE NUMBER(7,2)                                                             
,WR_RETURN_SHIP_COST NUMBER(7,2)                                                
,WR_REFUNDED_CASH NUMBER(7,2)                                                   
,WR_REVERSED_CHARGE NUMBER(7,2)                                                 
,WR_ACCOUNT_CREDIT NUMBER(7,2)                                                  
,WR_NET_LOSS NUMBER(7,2)                                                        
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
WR_RETURNED_DATE_SK                                                             
,WR_RETURNED_TIME_SK                                                            
,WR_ITEM_SK                                                                     
,WR_REFUNDED_CUSTOMER_SK                                                        
,WR_REFUNDED_CDEMO_SK                                                           
,WR_REFUNDED_HDEMO_SK                                                           
,WR_REFUNDED_ADDR_SK                                                            
,WR_RETURNING_CUSTOMER_SK                                                       
,WR_RETURNING_CDEMO_SK                                                          
,WR_RETURNING_HDEMO_SK                                                          
,WR_RETURNING_ADDR_SK                                                           
,WR_WEB_PAGE_SK                                                                 
,WR_REASON_SK                                                                   
,WR_ORDER_NUMBER                                                                
,WR_RETURN_QUANTITY                                                             
,WR_RETURN_AMT                                                                  
,WR_RETURN_TAX                                                                  
,WR_RETURN_AMT_INC_TAX                                                          
,WR_FEE                                                                         
,WR_RETURN_SHIP_COST                                                            
,WR_REFUNDED_CASH                                                               
,WR_REVERSED_CHARGE                                                             
,WR_ACCOUNT_CREDIT                                                              
,WR_NET_LOSS                                                                    
)) location ('web_returns.dat')                                                 
);                                                                              
------------------------------------------------------------------------------- 
drop table X_WEB_SALES;                                                         
create table X_WEB_SALES (                                                      
WS_SOLD_DATE_SK NUMBER(38)                                                      
,WS_SOLD_TIME_SK NUMBER(38)                                                     
,WS_SHIP_DATE_SK NUMBER(38)                                                     
,WS_ITEM_SK NUMBER(38)                                                          
,WS_BILL_CUSTOMER_SK NUMBER(38)                                                 
,WS_BILL_CDEMO_SK NUMBER(38)                                                    
,WS_BILL_HDEMO_SK NUMBER(38)                                                    
,WS_BILL_ADDR_SK NUMBER(38)                                                     
,WS_SHIP_CUSTOMER_SK NUMBER(38)                                                 
,WS_SHIP_CDEMO_SK NUMBER(38)                                                    
,WS_SHIP_HDEMO_SK NUMBER(38)                                                    
,WS_SHIP_ADDR_SK NUMBER(38)                                                     
,WS_WEB_PAGE_SK NUMBER(38)                                                      
,WS_WEB_SITE_SK NUMBER(38)                                                      
,WS_SHIP_MODE_SK NUMBER(38)                                                     
,WS_WAREHOUSE_SK NUMBER(38)                                                     
,WS_PROMO_SK NUMBER(38)                                                         
,WS_ORDER_NUMBER NUMBER(38)                                                     
,WS_QUANTITY NUMBER(38)                                                         
,WS_WHOLESALE_COST NUMBER(7,2)                                                  
,WS_LIST_PRICE NUMBER(7,2)                                                      
,WS_SALES_PRICE NUMBER(7,2)                                                     
,WS_EXT_DISCOUNT_AMT NUMBER(7,2)                                                
,WS_EXT_SALES_PRICE NUMBER(7,2)                                                 
,WS_EXT_WHOLESALE_COST NUMBER(7,2)                                              
,WS_EXT_LIST_PRICE NUMBER(7,2)                                                  
,WS_EXT_TAX NUMBER(7,2)                                                         
,WS_COUPON_AMT NUMBER(7,2)                                                      
,WS_EXT_SHIP_COST NUMBER(7,2)                                                   
,WS_NET_PAID NUMBER(7,2)                                                        
,WS_NET_PAID_INC_TAX NUMBER(7,2)                                                
,WS_NET_PAID_INC_SHIP NUMBER(7,2)                                               
,WS_NET_PAID_INC_SHIP_TAX NUMBER(7,2)                                           
,WS_NET_PROFIT NUMBER(7,2)                                                      
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
WS_SOLD_DATE_SK                                                                 
,WS_SOLD_TIME_SK                                                                
,WS_SHIP_DATE_SK                                                                
,WS_ITEM_SK                                                                     
,WS_BILL_CUSTOMER_SK                                                            
,WS_BILL_CDEMO_SK                                                               
,WS_BILL_HDEMO_SK                                                               
,WS_BILL_ADDR_SK                                                                
,WS_SHIP_CUSTOMER_SK                                                            
,WS_SHIP_CDEMO_SK                                                               
,WS_SHIP_HDEMO_SK                                                               
,WS_SHIP_ADDR_SK                                                                
,WS_WEB_PAGE_SK                                                                 
,WS_WEB_SITE_SK                                                                 
,WS_SHIP_MODE_SK                                                                
,WS_WAREHOUSE_SK                                                                
,WS_PROMO_SK                                                                    
,WS_ORDER_NUMBER                                                                
,WS_QUANTITY                                                                    
,WS_WHOLESALE_COST                                                              
,WS_LIST_PRICE                                                                  
,WS_SALES_PRICE                                                                 
,WS_EXT_DISCOUNT_AMT                                                            
,WS_EXT_SALES_PRICE                                                             
,WS_EXT_WHOLESALE_COST                                                          
,WS_EXT_LIST_PRICE                                                              
,WS_EXT_TAX                                                                     
,WS_COUPON_AMT                                                                  
,WS_EXT_SHIP_COST                                                               
,WS_NET_PAID                                                                    
,WS_NET_PAID_INC_TAX                                                            
,WS_NET_PAID_INC_SHIP                                                           
,WS_NET_PAID_INC_SHIP_TAX                                                       
,WS_NET_PROFIT                                                                  
)) location ('web_sales.dat')                                                   
);                                                                              
------------------------------------------------------------------------------- 
drop table X_WEB_SITE;                                                          
create table X_WEB_SITE (                                                       
WEB_SITE_SK NUMBER(38)                                                          
,WEB_SITE_ID CHAR(16)                                                           
,WEB_REC_START_DATE DATE                                                        
,WEB_REC_END_DATE DATE                                                          
,WEB_NAME VARCHAR2(50)                                                          
,WEB_OPEN_DATE_SK NUMBER(38)                                                    
,WEB_CLOSE_DATE_SK NUMBER(38)                                                   
,WEB_CLASS VARCHAR2(50)                                                         
,WEB_MANAGER VARCHAR2(40)                                                       
,WEB_MKT_ID NUMBER(38)                                                          
,WEB_MKT_CLASS VARCHAR2(50)                                                     
,WEB_MKT_DESC VARCHAR2(100)                                                     
,WEB_MARKET_MANAGER VARCHAR2(40)                                                
,WEB_COMPANY_ID NUMBER(38)                                                      
,WEB_COMPANY_NAME CHAR(50)                                                      
,WEB_STREET_NUMBER CHAR(10)                                                     
,WEB_STREET_NAME VARCHAR2(60)                                                   
,WEB_STREET_TYPE CHAR(15)                                                       
,WEB_SUITE_NUMBER CHAR(10)                                                      
,WEB_CITY VARCHAR2(60)                                                          
,WEB_COUNTY VARCHAR2(30)                                                        
,WEB_STATE CHAR(2)                                                              
,WEB_ZIP CHAR(10)                                                               
,WEB_COUNTRY VARCHAR2(20)                                                       
,WEB_GMT_OFFSET NUMBER(5,2)                                                     
,WEB_TAX_PERCENTAGE NUMBER(5,2)                                                 
)                                                                               
organization external (type oracle_loader default directory tpcsd_load_dir      
access parameters (                                                             
RECORDS DELIMITED BY NEWLINE                                                    
FIELDS TERMINATED BY '|'                                                        
(                                                                               
WEB_SITE_SK                                                                     
,WEB_SITE_ID                                                                    
,WEB_REC_START_DATE date "YYYY-MM-DD"                                           
,WEB_REC_END_DATE date "YYYY-MM-DD"                                             
,WEB_NAME                                                                       
,WEB_OPEN_DATE_SK                                                               
,WEB_CLOSE_DATE_SK                                                              
,WEB_CLASS                                                                      
,WEB_MANAGER                                                                    
,WEB_MKT_ID                                                                     
,WEB_MKT_CLASS                                                                  
,WEB_MKT_DESC                                                                   
,WEB_MARKET_MANAGER                                                             
,WEB_COMPANY_ID                                                                 
,WEB_COMPANY_NAME                                                               
,WEB_STREET_NUMBER                                                              
,WEB_STREET_NAME                                                                
,WEB_STREET_TYPE                                                                
,WEB_SUITE_NUMBER                                                               
,WEB_CITY                                                                       
,WEB_COUNTY                                                                     
,WEB_STATE                                                                      
,WEB_ZIP                                                                        
,WEB_COUNTRY                                                                    
,WEB_GMT_OFFSET                                                                 
,WEB_TAX_PERCENTAGE                                                             
)) location ('web_site.dat')                                                    
);                                                                              
