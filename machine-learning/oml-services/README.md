# Oracle Machine Learning Services on Autonomous Database - REST API Examples
OML Services extends OML functionality to support model deployment and model lifecycle management for both in- database OML models and third-party Open Neural Networks Exchange (ONNX) machine learning models via REST APIs.

The REST API for Oracle Machine Learning Services provides REST API endpoints hosted on Oracle Autonomous Database. These endpoints enable the storage of machine learning models along with its metadata, and the creation of scoring endpoints for the model.

Third-party classification or regression models are supported, and can be built using tools that support the ONNX format, which includes packages like Scikit-learn and TensorFlow, among several others.  OML Services also supports image classification functionality, through the ONNX format third-party model deployment feature, and supports scoring using images or tensors.

OML Services also has a built-in proprietary cognitive text capability, with capabilities for topic discovery, keywords, summary, sentiment, and feature extraction. The initial languages supported include English, Spanish, and French (based on a Wikipedia knowledgebase using embeddings).

Examples in this folder are:

* __oml-models__ - OML Models in serialized format, to be uset with the examples for loading models in via curl in the documentation or via Postman in the sample collection provided

* __postman-collection-examples__ - Examples from most of the REST APIs in separate Postman collections, including a sample Environment with a Testing Server

* __oml-services-swagger.json__ - OML Services Swagger file with all the REST API specifications
  
* __oml4sql-notebook-exporting-serialized-models.json__ - OML Notebooks with SQL code explaining in details how to export a serialized model from Autonomous Database.  Can also be used for any other Oracle Database.
  
For more information please visit the official documentation page [Oracle Machine Learning Services REST API](https://docs.oracle.com/en/cloud/paas/autonomous-data-warehouse-cloud/omlss/)

 #### Copyright (c) 2021 Oracle Corporation and/or its affilitiates.

 ###### [The Universal Permissive License (UPL), Version 1.0](https://oss.oracle.com/licenses/upl/)
