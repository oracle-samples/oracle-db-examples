# Oracle Machine Learning

## Overview
Oracle Machine Learning (OML) is a family of components that covers the range of cloud and on-premises offerings with Oracle Database and Oracle Autonomous Database.

Oracle Machine Learning enables you to solve key enterprise business problems and accelerates the development and deployment of data science and machine learning-based solutions. With OML, you benefit from scalable, automated, and secure data science and machine learning capabilities to meet the challenges of data exploration and preparation as well as model building, evaluation, and deployment. 

The OML tagline is “move the algorithms, not the data.” To realize this, we’ve placed powerful machine learning algorithms in the database kernel software – operating below the user security layer. Other tools simply can’t do that. OML eliminates data movement for database data and simplifies the solution architecture as there is no need to manage and test workflows involving third-party engines. 

OML extends the database to enable users to augment applications and dashboards with machine learning-based intelligence – quickly and easily – delivering over 30 in-database algorithms, accessible through multiple language interfaces. 

OML is part of the broader Oracle ecosystem for data analytics and machine learning that includes such tools as Oracle Data Integrator, Oracle Analytics Server and Analytics Cloud, OCI Data Science, AI Services, and others.

Applicable OML components are included with your Oracle Autonomous Database subscription and Oracle Database licenses – so you already have free access to it and you can just start using it.

## Components
OML provides support for the top three data science languages: SQL, R, and Python. OML4SQL provides a SQL interface to the in-database, parallelized algorithms, which keeps data under database control – eliminating the need to extract data to separate machine learning engines. This enables scalability while reducing complexity. 

OML4Py and OML4R are Python and R language interfaces, respectively. These allow you to manipulate database tables and views using familiar Python and R functions on DataFrame proxy objects, along with native APIs to use the in-database algorithms, and the ability to have the database spawn Python and R engines to run user-defined functions that may leverage additional third-party packages. Such user-defined functions can be invoked from native APIs as well as SQL and REST to facilitate solution deployment. OML4Py also supports automated machine learning (AutoML) through a Python API. 

For use on Autonomous Database Shared, OML Notebooks supports SQL, PL/SQL, Python, R, conda, and markdown interpreters. The same notebook can contain paragraphs with all or any of these interpreters – allowing users to choose the most effective language for the task. 

Oracle Data Miner is a SQL Developer extension that enables users to create, schedule, and deploy analytical workflows through a drag-and-drop user interface. It can be used with Oracle Database and Oracle Autonomous Database. 

Oracle Machine Learning AutoML UI is a no-code user interface that automates the model building, selection, and deployment process. It is available on Oracle Autonomous Database Shared. 

Oracle Machine Learning Services is a RESTful service for model deployment and management, data and model monitoring, and cognitive text analytics. Users can deploy a model from the AutoML UI directly to OML Services in just a few clicks. It is available on Oracle Autonomous Database Shared.

## Optimizations
Oracle Machine Learning is the only machine learning toolkit specifically designed to take advantage of Oracle Real Application Clusters and the Exadata platform.

Some of the optimizations include algorithms that leverage distributed parallelism and scalability across cluster nodes. Scoring takes advantage of function push-down to process data at the storage-tier (a unique Exadata feature), which makes scoring that much more scalable and performant.

One of the challenges with some other ML platforms is the need for data to fit in memory. With OML, data is brought into memory incrementally as needed. Further, models are cached and can be shared across queries when used for scoring.

OML leverages disk-aware structures – relying on the database memory manager for efficient allocation in multi-user environments.

And, when building or scoring partitioned models, not all component models need to be loaded.

## Summary
OML enables minimizing or eliminating data movement, supports multiple user personas through multiple languages and both code and no-code interfaces.

The in-database algorithms support scalable and high-performance modeling and scoring – taking advantage of RAC and Exadata optimizations, along with elastic scaling on Oracle Autonomous Database.

Automated Machine Learning (AutoML) makes machine learning more accessible to a broader set of users, whether through a Python API or no-code UI.

Data and model governance is directly supported via Oracle-enabled security in development and production. OML also enables flexible development, test, and deployment architectures in cloud, on-premises, and hybrid environments.

OML offers a simple pricing structure – machine learning capabilities included in core database at no additional cost.

These and other benefits resonate with customers needing powerful and integrated machine learning to meet their scalability and performance needs, while simplifying their solution and deployment architecture.

## More information
For more information please visit:
-  The official documentation page for OML at [docs.oracle.com/en/database/oracle/machine-learning](https://docs.oracle.com/en/database/oracle/machine-learning/)
-  The main website for OML on oracle.com at [oracle.com/goto/machine-learning](https://oracle.com/goto/machine-learning)
-  The Blogs from the Oracle Machine Learning team at [blogs.oracle.com/machinelearning/](https://blogs.oracle.com/machinelearning/)
-  The Hands-on workshops at Live Labs for OML at [bit.ly/omllivelabs](https://bit.ly/omllivelabs)



#### Copyright (c) 2023 Oracle Corporation and/or its affilitiates.

###### [The Universal Permissive License (UPL), Version 1.0](https://oss.oracle.com/licenses/upl/)
