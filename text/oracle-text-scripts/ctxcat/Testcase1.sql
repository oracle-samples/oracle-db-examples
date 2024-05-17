-- I'm not quite sure what this testcase was for, but it does illustrate a few things:
--   use of various parameters with a CTXCAT index
--   use of CONTEXT query grammar with a CTXCAT index
--

BEGIN
  CTX_DDL.DROP_PREFERENCE('myword');
END;
/
BEGIN
CTX_DDL.DROP_PREFERENCE('mymixed_case_lexer_pref');
END;
/
BEGIN
CTX_DDL.CREATE_PREFERENCE('myword', 'BASIC_WORDLIST'); 
CTX_DDL.SET_ATTRIBUTE('myword','SUBSTRING_INDEX', 'YES');
END;
/
BEGIN 
CTX_DDL.CREATE_PREFERENCE ('mymixed_case_lexer_pref','BASIC_LEXER'); 
-- CTX_DDL.SET_ATTRIBUTE ('mymixed_case_lexer_pref', 'printjoins', '@_%.');
CTX_DDL.SET_ATTRIBUTE ('mymixed_case_lexer_pref', 'mixed_case', 'TRUE'); 
END;
/
DROP TABLE DROP_ME_PLX;
CREATE TABLE DROP_ME_PLX (ID NUMBER GENERATED ALWAYS AS IDENTITY,ASD VARCHAR2(100));
CREATE INDEX DMP ON DROP_ME_PLX (ASD) INDEXTYPE IS CTXSYS.CTXCAT PARAMETERS ('WORDLIST myword LEXER mymixed_case_lexer_pref');
DELETE FROM DROP_ME_PLX;
INSERT INTO DROP_ME_PLX (ASD) VALUES (NULL);
INSERT INTO DROP_ME_PLX (ASD) VALUES ('test@test.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('tu@sit.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('anne@sit.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('test_company@test.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('test_c@test.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('test2@test.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('john@sit.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('test3@test.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('test3@test_email.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('te3@test_email.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('t@te_email.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('t@te_1te23il.com');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('test3@test_email.testing');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('test3@tes_t_email.tesng');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('asd3@test_email.teting');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('wer3@test_email.teng');
INSERT INTO DROP_ME_PLX (ASD) VALUES ('wer3@testasdasdgrfhetest_heuatryaeryeryerqyqryyqrytesting_email.teng');
COMMIT;

SELECT * FROM DROP_ME_PLX where asd like '%test\_%' ESCAPE '\';

WITH DMP2 AS
(
SELECT * FROM DROP_ME_PLX WHERE CATSEARCH (ASD,'<query><textquery grammar="context">%test%</textquery></query>',NULL) > 0
)
SELECT * FROM DROP_ME_PLX DMP1, DMP2
WHERE DMP1.ASD LIKE '%test%'
  AND DMP1.ID = DMP2.ID (+);

WITH DMP2 AS
(
SELECT * FROM DROP_ME_PLX WHERE CATSEARCH (ASD,'<query><textquery grammar="context">%te%</textquery></query>',NULL) > 0
)
SELECT * FROM DROP_ME_PLX DMP1, DMP2
WHERE DMP1.ASD LIKE '%te%'
  AND DMP1.ID = DMP2.ID (+);

WITH DMP2 AS
(
SELECT * FROM DROP_ME_PLX WHERE CATSEARCH (ASD,'<query><textquery grammar="context">%test_%</textquery></query>',NULL) > 0
)
SELECT * FROM DROP_ME_PLX DMP1, DMP2
WHERE DMP1.ASD LIKE '%test_%'
  AND DMP1.ID = DMP2.ID (+);

WITH DMP2 AS
(
SELECT * FROM DROP_ME_PLX WHERE CATSEARCH (ASD,'<query><textquery grammar="context">%test\_%</textquery></query>',NULL) > 0
)
SELECT * FROM DROP_ME_PLX DMP1, DMP2
WHERE DMP1.ASD LIKE '%test\_%' ESCAPE '\'
  AND DMP1.ID = DMP2.ID (+);

WITH DMP2 AS
(
SELECT * FROM DROP_ME_PLX WHERE CATSEARCH (ASD,'<query><textquery grammar="context">%test.%</textquery></query>',NULL) 0
)
SELECT * FROM DROP_ME_PLX DMP1, DMP2
WHERE DMP1.ASD LIKE '%test.%'
  AND DMP1.ID = DMP2.ID (+);

WITH DMP2 AS
(
SELECT * FROM DROP_ME_PLX WHERE CATSEARCH (ASD,'<query><textquery grammar="context">%.%</textquery></query>',NULL) > 0
)
SELECT * FROM DROP_ME_PLX DMP1, DMP2
WHERE DMP1.ASD LIKE '%.%'
  AND DMP1.ID = DMP2.ID (+);

WITH DMP2 AS
(
SELECT * FROM DROP_ME_PLX WHERE CATSEARCH (ASD,'<query><textquery grammar="context">%.t%</textquery></query>',NULL) > 0
)
SELECT * FROM DROP_ME_PLX DMP1, DMP2
WHERE DMP1.ASD LIKE '%.t%'
  AND DMP1.ID = DMP2.ID (+);

WITH DMP2 AS
(
SELECT * FROM DROP_ME_PLX WHERE CATSEARCH (ASD,'<query><textquery grammar="context">%testing%</textquery></query>',NULL) > 0
)
SELECT * FROM DROP_ME_PLX DMP1, DMP2
WHERE DMP1.ASD LIKE '%testing%'
  AND DMP1.ID = DMP2.ID (+);
