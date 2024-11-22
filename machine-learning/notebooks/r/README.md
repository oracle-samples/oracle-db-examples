# Oracle Machine Learning for R

## Introduction

Oracle Machine Learning for R (OML4R) supports scalable in-database data exploration and preparation using native R syntax, scalable in-database algorithms for machine learning model building and scoring. Users can also invoke user-defined R functions from R, SQL and (on Autonomous Database) REST APIs using database-spawned R engines. OML4R increases data scientist productivity and reduces solution deployment complexity.

R is a major programming language used for data science and machine learning. OML4R is a feature of Oracle Autonomous Database and Oracle Database that provides R users access to powerful in-database functionality supporting data scientists and other R users for both scalability, performance, and ease of solution deployment. 

## Key Features of OML4R

Transparency layer
* Leverage proxy objects so data remains in database
* Overload native functions translating functionality to SQL
* Use familiar R syntax on database data
Parallel, distributed in-database algorithms
* Scalability and performance
* Exposes in-database algorithms available from OML4SQL
Embedded execution
* Manage and invoke R user-defined functions in the database 
* Invoke using system-provided data-parallel, task-parallel, and non-parallel behavior
* Use open-source packages to augment functionality

## OML Notebooks

Oracle Machine Learning Notebooks is a collaborative user interface for data scientists and business and data analysts who perform machine learning in Oracle Autonomous Database. OML Notebooks enables you to explore data visually and develop analytical methodologies in Autonomous Database. Through OML Notebooks, you can work with R and OML4R, but also Python OML4Py, SQL, PL/SQL, and OML4SQL. 

Oracle's high performance, parallel and scalable in-database implementations of machine learning algorithms are exposed via SQL, PL/SQL, R, and Python APIs. Oracle Machine Learning enables teams to collaborate to build, assess, and deploy machine learning models, while increasing data scientist productivity Oracle Machine Learning focuses on ease of use and simplified machine learning for data science – from preparation through deployment – all in Oracle Autonomous Database and Oracle Database.

Multi-user collaboration enables the same notebook document to be opened simultaneously by different users, such that changes made by one user to a notebook are reflected to all users viewing that notebook. To support enterprise requirements for security, authentication, and auditing, Oracle Machine Learning supports privilege-based access to data, models, and notebooks, as well as being integrated with Oracle security protocols.

## Key Features of OML Notebooks

Collaborative UI 
* Data scientists, developers and DBAs use built-in SQL, R, Python, conda, and markdown interpreters
* Import/export Zeppelin/Jupyter format notebooks
* Schedule, version, and control access to notebooks
* Add comments on individual notebooks paragraphs

Included with Autonomous Database
* Automatically provisioned and managed
* Use in-database algorithms and analytics functions 
* Explore and prepare data, build and evaluate models, score data, and deploy solutions
* Create conda environments with third-party R and Python packages and use in notebook paragraphs

## Notebooks using OML4Py

This current folder contains the examples based on Oracle Machine Learning for R (OML4R), from data preparation and transformation to the machine learning modeling and solution deployment.

The specific denomination "OfficeHours_" in the name of the file indicates that the Notebook was presented at one of the previous sessions of the [AskTOM Oracle Machine Learning Office Hours](https://asktom.oracle.com/pls/apex/asktom.search?oh=6801#sessions).

## Documentation

[Oracle Machine Learning for R](https://docs.oracle.com/en/database/oracle/machine-learning/oml4r/index.html)

[Oracle Machine Learning Notebooks](https://docs.oracle.com/en/database/oracle/machine-learning/oml-notebooks/)

#### Copyright (c) 2024 Oracle Corporation and/or its affilitiates.

###### [The Universal Permissive License (UPL), Version 1.0](https://oss.oracle.com/licenses/upl/)
