create table
pos_data (
   start_date        DATE,
   store_id          NUMBER,
   inventory_id      NUMBER(6),
   qty_sold          NUMBER(3),
   text              VARCHAR2(200)
)
PARTITION BY RANGE (start_date)
INTERVAL(NUMTOYMINTERVAL(1, 'MONTH'))
( 
   PARTITION pos_data_p2 VALUES LESS THAN (TO_DATE('1-7-2007', 'DD-MM-YYYY')),
   PARTITION pos_data_p3 VALUES LESS THAN (TO_DATE('1-8-2007', 'DD-MM-YYYY'))
); 

create index pos_index on pos_data (text) 
indextype is ctxsys.context
local
/
