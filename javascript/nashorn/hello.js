function hello()
{
/*
*This is a sample Javascript file that prints "Hello World".
*
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
