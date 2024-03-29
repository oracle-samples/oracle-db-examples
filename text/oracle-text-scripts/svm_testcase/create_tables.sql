DROP TABLE test.brain;
DROP TABLE test.cancer;
DROP TABLE test.maternal;
DROP TABLE test.microbes;
DROP TABLE test.synmed;
drop table test.training_abstracts;
drop sequence test.abstract_seq;


CREATE TABLE test.brain ( abstract      CLOB);
CREATE TABLE test.cancer ( abstract      CLOB);
CREATE TABLE test.maternal ( abstract      CLOB);
CREATE TABLE test.microbes ( abstract      CLOB);
CREATE TABLE test.synmed ( abstract      CLOB);

create table test.training_abstracts ( docid number primary key, abstract CLOB );
create sequence test.abstract_seq start with 1;

