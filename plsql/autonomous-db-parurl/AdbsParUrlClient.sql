-- Copyright (c) 2024, Oracle and/or its affiliates.
-- The Universal Permissive License (UPL), Version 1.0
--
-- Subject to the condition set forth below, permission is hereby granted to any
-- person obtaining a copy of this software, associated documentation and/or data
-- (collectively the "Software"), free of charge and under any and all copyright
-- rights in the Software, and any and all patent rights owned or freely
-- licensable by each licensor hereunder covering either (i) the unmodified
-- Software as contributed to or provided by such licensor, or (ii) the Larger
-- Works (as defined below), to deal in both
--
-- (a) the Software, and
-- (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
-- one is included with the Software (each a "Larger Work" to which the Software
-- is contributed by such licensors),
--
-- without restriction, including without limitation the rights to copy, create
-- derivative works of, display, perform, and distribute the Software and make,
-- use, sell, offer for sale, import, export, have made, and have sold the
-- Software and the Larger Work(s), and to sublicense the foregoing rights on
-- either these or other terms.
--
-- This license is subject to the following condition:
-- The above copyright notice and either this complete permission notice or at
-- a minimum a reference to the UPL must be included in all copies or
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

Rem
Rem AdbsParUrlClient.sql
Rem
Rem    NAME
Rem      AdbsParUrlPlClient.sql - PL/SQL script to fetch Autonomous Database pre-authenticated request url data.
Rem
Rem    NOTES
Rem     None.

SET SERVEROUTPUT ON
/

-----------------------------------------------
-- ADBS Pre auth Request Example package ------
-----------------------------------------------
CREATE OR REPLACE PACKAGE ADBS_PAR_URL_CLIENT
IS
    NEXT_GET_PAR_URL          VARCHAR2(1024);
    COLLECTION_INDEX_POSITION NUMBER;
    ITEMS                     JSON_ARRAY_T;
    ITEMS_SIZE                NUMBER;
    TOTAL_RECORDS             NUMBER;

    PROCEDURE SET_PAR_URL(PAR_URL IN VARCHAR2);
    FUNCTION GET_NEXT_ITEM RETURN CLOB;
END;
/

----------------------------------------------------
-- ADBS Pre auth Request Example package Body ------
----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY ADBS_PAR_URL_CLIENT
IS
    PROCEDURE SET_PAR_URL(PAR_URL IN VARCHAR2)
    IS
    BEGIN
        ADBS_PAR_URL_CLIENT.NEXT_GET_PAR_URL := PAR_URL;
        ADBS_PAR_URL_CLIENT.COLLECTION_INDEX_POSITION := 0;
        ADBS_PAR_URL_CLIENT.ITEMS := JSON_ARRAY_T('[]');
        ADBS_PAR_URL_CLIENT.ITEMS_SIZE := 0;
        ADBS_PAR_URL_CLIENT.TOTAL_RECORDS := 0;
    END;

    FUNCTION GET_NEXT_ITEM
        RETURN CLOB
    IS
        HTTP_REQUEST  UTL_HTTP.REQ;
        HTTP_RESPONSE UTL_HTTP.RESP;
        RESPONSE_CODE NUMBER;
        RESPONSE_CONTENT  CLOB;
        TEMP_BUFFER   VARCHAR2(32767);
        LINKS JSON_ARRAY_T;
        HAS_MORE VARCHAR2(32767);
        JSON_OBJ JSON_OBJECT_T;
    BEGIN

       IF ADBS_PAR_URL_CLIENT.COLLECTION_INDEX_POSITION < ADBS_PAR_URL_CLIENT.ITEMS_SIZE THEN
            ADBS_PAR_URL_CLIENT.COLLECTION_INDEX_POSITION := ADBS_PAR_URL_CLIENT.COLLECTION_INDEX_POSITION + 1;
            RETURN ADBS_PAR_URL_CLIENT.ITEMS.GET(ADBS_PAR_URL_CLIENT.COLLECTION_INDEX_POSITION - 1).to_Clob;
        ELSE
            IF ADBS_PAR_URL_CLIENT.NEXT_GET_PAR_URL IS NOT NULL THEN

                -- Iterate and remove each item from the global array
                FOR itemsIndx IN 0 .. ADBS_PAR_URL_CLIENT.ITEMS.get_size - 1
                LOOP
                    ADBS_PAR_URL_CLIENT.ITEMS.REMOVE(itemsIndx);
                END LOOP;

                -- Initialize the CLOB.
                DBMS_LOB.CREATETEMPORARY(RESPONSE_CONTENT, false);

                HTTP_REQUEST := UTL_HTTP.BEGIN_REQUEST(ADBS_PAR_URL_CLIENT.NEXT_GET_PAR_URL, 'GET');
                UTL_HTTP.SET_HEADER(HTTP_REQUEST, 'CONTENT-TYPE', 'application/json');

                DBMS_OUTPUT.PUT_LINE('Invoking Get Request On Url: ' || ADBS_PAR_URL_CLIENT.NEXT_GET_PAR_URL);

                -- Get response.
                HTTP_RESPONSE := UTL_HTTP.GET_RESPONSE(HTTP_REQUEST);

                -- Status code
                RESPONSE_CODE := HTTP_RESPONSE.STATUS_CODE;
                DBMS_OUTPUT.PUT_LINE('Response received. STATUS=' || RESPONSE_CODE);
                DBMS_OUTPUT.PUT_LINE('Response received. REASON_PHRASE=' || HTTP_RESPONSE.reason_phrase);
                DBMS_OUTPUT.PUT_LINE('Response received. HTTP_VERSION=' || HTTP_RESPONSE.http_version);

                IF HTTP_RESPONSE.STATUS_CODE = 200 THEN
                    BEGIN
                        -- Copy the response into the intermediate CLOB.
                        LOOP
                            UTL_HTTP.READ_TEXT(HTTP_RESPONSE, TEMP_BUFFER, 32766);
                            RESPONSE_CONTENT := RESPONSE_CONTENT || TEMP_BUFFER;
                        END LOOP;

                        UTL_HTTP.END_RESPONSE(HTTP_RESPONSE);

                    EXCEPTION
                        WHEN UTL_HTTP.END_OF_BODY THEN
                            UTL_HTTP.END_RESPONSE(HTTP_RESPONSE);

                        WHEN OTHERS THEN
                            DBMS_OUTPUT.PUT_LINE(SQLERRM);
                            DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                            UTL_HTTP.END_RESPONSE(HTTP_RESPONSE);
                    END;

                    JSON_OBJ := JSON_OBJECT_T( RESPONSE_CONTENT );
                    ADBS_PAR_URL_CLIENT.ITEMS := JSON_OBJ.GET_ARRAY('items');
                    DBMS_OUTPUT.PUT_LINE('size:' || ADBS_PAR_URL_CLIENT.ITEMS.get_size);
                    ADBS_PAR_URL_CLIENT.TOTAL_RECORDS := ADBS_PAR_URL_CLIENT.TOTAL_RECORDS + ADBS_PAR_URL_CLIENT.ITEMS.get_size;
                    ADBS_PAR_URL_CLIENT.COLLECTION_INDEX_POSITION := 0;
                    ADBS_PAR_URL_CLIENT.ITEMS_SIZE := ADBS_PAR_URL_CLIENT.ITEMS.get_size;

                    -- Get the links field from the json response
                    LINKS := JSON_OBJ.GET_ARRAY('links');

                    -- Iterate and get the next page href if available
                    FOR linksIndx IN 0 .. LINKS.get_size - 1
                    LOOP
                        IF JSON_OBJECT_T( LINKS.get(linksIndx)).GET_STRING('rel') = 'next' THEN
                            ADBS_PAR_URL_CLIENT.NEXT_GET_PAR_URL := JSON_OBJECT_T(LINKS.get(linksIndx)).GET_STRING('href');
                            DBMS_OUTPUT.PUT_LINE('next href: ' || ADBS_PAR_URL_CLIENT.NEXT_GET_PAR_URL);
                        END IF;
                    END LOOP;

                    -- Get the hasMore field from the json response
                    HAS_MORE := JSON_OBJ.GET_STRING('hasMore');
                    DBMS_OUTPUT.PUT_LINE('hasMore: ' || HAS_MORE);

                    IF HAS_MORE = 'false' THEN
                        ADBS_PAR_URL_CLIENT.NEXT_GET_PAR_URL := NULL;
                    END IF;

                    -- Relase the resources associated with the temporary LOB.
                    DBMS_LOB.FREETEMPORARY(RESPONSE_CONTENT);
                    ADBS_PAR_URL_CLIENT.COLLECTION_INDEX_POSITION := COLLECTION_INDEX_POSITION + 1;
                    RETURN ADBS_PAR_URL_CLIENT.ITEMS.GET(ADBS_PAR_URL_CLIENT.COLLECTION_INDEX_POSITION - 1).to_Clob;
                ELSE
                    ADBS_PAR_URL_CLIENT.NEXT_GET_PAR_URL := NULL;
                    DBMS_OUTPUT.PUT_LINE('ERROR');
                    UTL_HTTP.END_RESPONSE(HTTP_RESPONSE);
                    RETURN NULL;
                END IF;
            ELSE
                RETURN NULL;
            END IF;
        END IF;
    END;
END;
/

-------------------------------------------
---------- Get Pre Auth Url Data ----------
-------------------------------------------
DECLARE
    ITEM CLOB;
BEGIN
    ADBS_PAR_URL_CLIENT.SET_PAR_URL('https://dataaccess.adb.us-phoenix-1.oraclecloudapps.com/adb/p/NYGM5PicEMTe.../data');
    LOOP
        ITEM := ADBS_PAR_URL_CLIENT.GET_NEXT_ITEM();
        DBMS_OUTPUT.PUT_LINE(ITEM);
    EXIT WHEN ITEM IS NULL;
    END LOOP;
END;

