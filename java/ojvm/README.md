# OJVM based examples
This folder stores Java based examples for the embedded JVM of the Oracle Database (a.k.a. OJVM). We are referring to plain Java code
with embedded SQL statements, similar to client JDBC code. 

The motivations for running Java code directly in the database include: 
* reusing Java code, Java libraries, and Java skills (developers) for database modules written in Java thereby allowing the same
  language across the mid-tier and the database-tier. The embedded JVM (a.k.a. OJVM also allows JavaScript (see our examples), Scala
  (see [Igor Racic's examples](http://www.igorandsons.com/)). I also described in [chapter 5 of my book](https://www.amazon.com/dp/1555583296), how to run run Jython, Jacl, Scheme, and Groovy in the database 
* the other key reason for running Java directly in the database is performance; really? Yes, even if HotSpot or external JVMs run
  pure Java sligthly faster than OJVM (but no one runs pure Java code i.e., Fibonnaci computation in the database), running Java in
  the database cuts the network traffic incurred by the steps involved in processing SQL statements (i.e., parse, and/or bind, and/or
  execute, and fetches).
  You can see for yourself with the TrimBlog and Workers examples (running both inside and outside the database).

[Documentation](http://docs.oracle.com/database/122/JJDEV/toc.htm)

[What's in Oracle database 12c Release 2 for Java & JavaScript Developers?](http://bit.ly/2orH5jf)

[Community Forum](https://community.oracle.com/community/database/developer-tools/jvm)
