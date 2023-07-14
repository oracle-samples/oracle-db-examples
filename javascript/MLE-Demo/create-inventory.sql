drop table if exists inventory;
create table inventory(
    id VARCHAR(128) PRIMARY KEY NOT NULL,
    stock NUMBER
);
