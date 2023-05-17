# Oracle Machine Learning Services on Autonomous Database - REST API Examples
OML Services extends OML functionality to support model deployment and model lifecycle management for both native in-database OML models and third-party Open Neural Networks Exchange (ONNX) machine learning models via REST APIs. 

OML Services support for scoring data includes real-time singleton and small batch scoring for native and ONNX-format models, and asynchronous batch scoring for native models. See the [documentation](https://docs.oracle.com/en/database/oracle/machine-learning/omlss/omlss/introduction.html) for details. 
OML Services Monitoring for native models enables users to monitor data for changes from a baseline dataset. Data monitoring can help maintain organizational data quality standards to help ensure the integrity of enterprise applications and dashboards. OML Services expands support for the machine learning lifecycle and MLOps with the combination of data monitoring and model monitoring.  

The REST API for OML Services provides REST endpoints hosted with Oracle Autonomous Database.

OML Services supports third-party ONNX-format classification, regression, and classification models, which can be produced externally using packages like Scikit-learn and TensorFlow, among others. OML Services also supports image classification using third-party ONNX format models with scoring via images or tensors.

OML Services also has a built-in proprietary cognitive text capability, with capabilities for topic discovery, keywords, summary, sentiment (English only), and feature extraction. The languages supported include English, Spanish, French, and Italian (based on a Wikipedia knowledgebase using embeddings).

Examples in this folder are:

* __oml-models__ - OML Models in serialized format, to be used with the examples for loading models in via cURL in the documentation or via Postman in the sample collection provided

* __postman-collection-examples__ - Examples from most of the REST APIs in separate Postman collections, including a sample Environment with a testing server

* __oml-services-swagger.json__ - OML Services swagger file with all the REST API specifications
  
* __oml4sql-notebook-exporting-serialized-models.json__ - notebooks with SQL code explaining in details how to export a serialized model from Oracle Autonomous Database and any other Oracle Database.
  
For more information please visit the official documentation page [Oracle Machine Learning Services REST API](https://docs.oracle.com/en/cloud/paas/autonomous-data-warehouse-cloud/omlss/)

 #### Copyright (c) 2023 Oracle Corporation and/or its affilitiates.

 ###### [The Universal Permissive License (UPL), Version 1.0](https://oss.oracle.com/licenses/upl/)
