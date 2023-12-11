CREATE OR REPLACE PACKAGE da_pipe AS
 PROCEDURE read_pipe  (timeonpipe          IN NUMBER,
                          endofpipe          OUT NUMBER);
 PROCEDURE load_pipe  (thetime             IN DATE);
 PROCEDURE da_main;
END da_pipe;
/
CREATE OR REPLACE PACKAGE BODY da_pipe AS
namedpipe             VARCHAR2(30);
endofpipe             NUMBER;
timeonpipe            NUMBER;
pipe_returncode       NUMBER;
p_thetime             DATE;
load_timeout          NUMBER := 30;
load_size             NUMBER := 4096;
PROCEDURE load_pipe (thetime    IN DATE) IS
BEGIN
 DBMS_PIPE.PACK_MESSAGE(namedpipe);
 DBMS_PIPE.PACK_MESSAGE(thetime);
 pipe_returncode := DBMS_PIPE.SEND_MESSAGE(namedpipe,load_timeout,load_size);
END load_pipe;
PROCEDURE read_pipe (timeonpipe IN NUMBER,
                     endofpipe OUT NUMBER) IS
BEGIN
 endofpipe := 0;
 pipe_returncode := DBMS_PIPE.RECEIVE_MESSAGE(namedpipe, timeonpipe);
 IF pipe_returncode = 0 THEN
  DBMS_PIPE.UNPACK_MESSAGE(namedpipe);
  DBMS_PIPE.UNPACK_MESSAGE(p_thetime);
  DBMS_OUTPUT.PUT_LINE(namedpipe||' : '||to_char(p_thetime,'MM/DD/YYYY:HH24:MI:SS'));
 ELSE
  endofpipe := 1;
 END IF;
END read_pipe;
PROCEDURE da_main IS
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SESSION_USER',30) 
    INTO namedpipe FROM DUAL;
  dbms_output.put_line('sending');
  load_pipe(sysdate);
  dbms_output.put_line('sending');
  load_pipe(sysdate);
  dbms_output.put_line('sending');
  load_pipe(sysdate);
  timeonpipe := 10;
  LOOP
    dbms_output.put_line('receiving');
    read_pipe(timeonpipe, endofpipe);
    IF endofpipe = 1 THEN
      return;
    END IF;
  END LOOP;
END da_main;
BEGIN
  DBMS_OUTPUT.ENABLE(1000000);
END da_pipe;
/


