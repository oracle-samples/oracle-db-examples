CONNECT SYSTEM/password

ALTER USER ctxsys IDENTIFIED BY password ACCOUNT UNLOCK;

CONNECT ctxsys/password

CREATE TABLE ctxsys.index_errors_persist
      ( err_idx_id    NUMBER,
        err_timestamp DATE,
        err_textkey   VARCHAR2(18),
        err_text      VARCHAR2(4000) );

CREATE OR REPLACE TRIGGER save_index_errors
  BEFORE INSERT ON ctxsys.dr$index_error
  FOR EACH ROW
BEGIN
    INSERT INTO ctxsys.index_errors_persist
      ( err_idx_id,
        err_timestamp,
        err_textkey,
        err_text )
      VALUES
      ( :new.err_idx_id,
        :new.err_timestamp,
        :new.err_textkey,
        :new.err_text );
END;
/
show error

CONNECT SYSTEM/password

ALTER USER ctxsys ACCOUNT LOCK;
