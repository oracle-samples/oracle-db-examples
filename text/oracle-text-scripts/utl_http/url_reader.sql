CREATE TABLE WWW_DATA (num NUMBER, dat CLOB)
/

set serverout on

CREATE OR REPLACE PROCEDURE WWW_GET(url VARCHAR2)
IS
    request UTL_HTTP.REQ;
    response UTL_HTTP.RESP;
    n NUMBER;
    buff VARCHAR2(4000);
    clob_buff CLOB;
BEGIN
    UTL_HTTP.SET_RESPONSE_ERROR_CHECK(FALSE);
    request := UTL_HTTP.BEGIN_REQUEST(url, 'GET');
    UTL_HTTP.SET_HEADER(request, 'User-Agent', 'Mozilla/4.0');
    response := UTL_HTTP.GET_RESPONSE(request);
    DBMS_OUTPUT.PUT_LINE('HTTP response status code: ' || response.status_code);
 
    IF response.status_code = 200 THEN
        BEGIN
            clob_buff := EMPTY_CLOB;
            LOOP
                UTL_HTTP.READ_TEXT(response, buff, LENGTH(buff));
		clob_buff := clob_buff || buff;
            END LOOP;
	    UTL_HTTP.END_RESPONSE(response);
	EXCEPTION
	    WHEN UTL_HTTP.END_OF_BODY THEN
                UTL_HTTP.END_RESPONSE(response);
	    WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(SQLERRM);
                DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                UTL_HTTP.END_RESPONSE(response);
        END;
 
	SELECT COUNT(*) + 1 INTO n FROM WWW_DATA;
        INSERT INTO WWW_DATA VALUES (n, clob_buff);
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR');
        UTL_HTTP.END_RESPONSE(response);
    END IF;
  
END;
/
SHOW ERRORS
/

-- Test a read from slc07dif

EXEC WWW_GET('http://slc07dif.us.oracle.com:8080/Filemgr/DownloadServlet?FSbdg=%7BAES%3A128%7D4C44882798C17EEFD1DAA826891A0B042B278B480D67B09FBAF91CFEB28F1DE64AA4583214BE5D6ABC0A5019ADA57C97640B&vault=&fileID=%7BAES%3A128%7D2B0C380118F4C17A42790859317BC7957590')
/
