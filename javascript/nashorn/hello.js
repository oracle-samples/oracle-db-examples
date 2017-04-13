function hello()
{
/*
* This is a sample Javascript file that prints "Hello World".
*
* As indicated, your database user must have been granted the DBJAVASCRIPT role
* Before invoking it, you must load it into your database user schema
* loadjava –v –r –u hr/hr hello.js
* then call hello.js from SQL*Plus
* SQL> @hello.sql
*/
var hellow = "Hello World";
return hellow;
}
var output = hello();
print(output);
