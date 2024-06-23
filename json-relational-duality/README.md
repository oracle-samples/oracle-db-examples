# Oracle 23ai JSON Relational Duality

JSON Relational Duality is a new capability in Oracle Database 23ai that unifies the benefits of both the relational and document models.

Until now, developers have had to use either the relational model or the JSON document model, to both store and access application data. Therefore, they had to make a choice that involved acquiring the benefits as well as the drawbacks of the model they selected:

The relational data model is ideal as a storage format due to the power of normalization, which eliminates data duplication and provides consistency and efficiency. However, the relational model is not as ideal as an access format for building applications since applications process data in terms of hierarchical objects. 

The document model, such as JSON, is ideal as an access format since it is hierarchical and self-contained, making it easy to map to application objects. However, JSON documents are poor as a storage format since different documents can repeat the same data, resulting in data duplication, updates to multiple copies, and, therefore, potential inconsistencies—the very problem that the relational model solves via normalization.

JSON Relational Duality is a breakthrough innovation that overcomes the historical challenges developers have faced when choosing between a relational model or a document model for building applications. Developers can now get the flexibility and data access simplicity of the document model as well as the efficiency, consistency, and use case flexibility of the relational model on the same underlying data.

Read more about the feature using the blog and documentation links below.

## JSON Relational Duality Tutorial

This directory includes the tutorials related to JSON Relational Duality. The tutorial scripts walk you through examples of working with JSON Relational Duality Views using Formula-1 (auto-racing) season data through SQL and Oracle Database API for MongoDB. Tutorials are independent and self-sufficient. They start from the basics and guide users step by step through the process of learning about JSON Relational Duality.


## Documentation

See the [JSON Relational Duality Developer's Guide]( 
https://docs.oracle.com/en/database/oracle/oracle-database/23/jsnvu/index.html) for details on the JSON Relational Duality functionality.

## Feature home page 

[Oracle 23ai JSON Relational Duality Feature page](https://www.oracle.com/database/json-relational-duality): Check out feature description, benefits and other links to resources.

## Video
[Revolutionizing objects, documents, and relational development](https://www.youtube.com/watch?v=e8-jBkO1NqY)

## Blogs

Check out the following blogs:
* [Oracle Announces General Availability of JSON Relational Duality in Oracle Database 23ai](https://blogs.oracle.com/database/post/oracle-announces-general-availability-of-json-relational-duality-in-oracle-database-23ai)
*	[Concept & overview of JSON Relational Duality](https://blogs.oracle.com/database/post/json-relational-duality-app-dev?source=:so:ch:or:awr::::OCW23cbeta)
* [REST with JSON Relational Duality](https://www.thatjeffsmith.com/archive/2023/04/oracle-database-23c-json-relational-duality-views-rest-apis/)
*	[Use Oracle Database API for MongoDB with JSON Relational Duality](https://blogs.oracle.com/datawarehousing/post/use-json-relational-duality-with-oracle-database-api-for-mongo-db)

## Use JSON Relational Duality with other tools, frameworks and APIs

*	[Python API](https://medium.com/oracledevs/python-oracledb-1-3-supports-oracle-database-23c-json-relational-duality-62d3c9d13f07)
*	[ODP.NET](https://medium.com/oracledevs/odp-net-json-relational-duality-and-oracle-database-23c-free-9e4c03bdf41f)
* [Micronaut Framework](https://blogs.oracle.com/java/post/json-relational-duality-views-with-micronaut-framework)
* [APEX REST API](https://diveintoapex.com/2024/03/05/simplify-apex-app-rest-apis-with-json-duality-views/)

  
## Demo

* [Demo: AskTom Office Hour - JSON Relational Duality](https://www.youtube.com/watch?v=fZtJanRsMgY)
