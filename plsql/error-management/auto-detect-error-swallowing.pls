/*

Automatically Detect Exception Handlers That ''Swallow Up'' Errors

Use compile time warnings to be warned if the compiler has identified an exception handler that does 
not contain a RAISE statement or a call to RAISE_APPLICATION_ERROR.

LiveSQL link: https://livesql.oracle.com/apex/livesql/file/content_C0VIPVWBK1FY057S1ZOOMKXE2.html

*/

/* Force 6009 Warning as a Compile Error 

Not only does this demonstrate a very cool feature of compile-time warnings (you can convert a warning into an error), 
but it also gets around a (current) limitation of LiveSQL: it is not yet displaying compile time warnings. Only 
compile failures. PLW-06009 warning is: "PLW-06009: procedure "string" OTHERS handler does not end in RAISE or 
RAISE_APPLICATION_ERROR" Cause: The OTHERS handler can exit without executing some form of RAISE or or a call 
to the standard procedure RAISE_APPLICATION_ERROR.

*/

ALTER SESSION SET plsql_warnings = 'Error:6009'
/

/* A RETURN is Not a Re-raise - FAIL! */

CREATE OR REPLACE FUNCTION plw6009 
   RETURN VARCHAR2 
AS 
BEGIN 
   RETURN 'abc'; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      RETURN 'abc'; 
END plw6009;
/

/* A Re-raise of the Current Exception - OK! */

CREATE OR REPLACE FUNCTION plw6009 
   RETURN VARCHAR2 
AS 
BEGIN 
   RETURN 'abc'; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      RAISE; 
END plw6009;
/

/* Raise a New Error - OK! */

CREATE OR REPLACE FUNCTION plw6009 
   RETURN VARCHAR2 
AS 
BEGIN 
   RETURN 'abc'; 
EXCEPTION 
   WHEN OTHERS 
   THEN 
      RAISE_APPLICATION_ERROR (-20000, 'I am raising an exception!'); 
END plw6009;
/


