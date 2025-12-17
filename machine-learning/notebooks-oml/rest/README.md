# Oracle Machine Learning Services

## Introduction

Oracle Machine Learning Services provides a REST API to support data monitoring, model monitoring, model deployment, model lifecycle management for both in-database OML models and third-party Open Neural Networks Exchange (ONNX) format machine learning models through REST APIs.

With OML Services on Autonomous Database, you can manage and deploy machine learning models using a REST API for flexible application integration. Scoring using these models is optimized for streaming and real-time applications - often with millisecond response times. Unlike other solutions that require provisioning a VM for 24x7 availability, OML Services is provisioned and maintained as part of Autonomous Database, so you pay only the additional compute when producing actual predictions. 

The model management and deployment services enable you to deploy in-database models produced from both Oracle Database and Autonomous Database. OML Services enables data monitoring and model monitoring. Data monitoring flags data drift to highlight potential data quality issues. Model monitoring flags models concept drift and changes in quality metrics. 

OML Services also supports cognitive text analytics, like extracting topics and keywords, sentiment analysis, and text summary and similarity.

## Key Features of OML Services

Model Management
* Store and organize models
* Version and compare models
Model Deployment
* Real-time scoring/inferencing
* Singleton, small batch, and full batch scoring
* Deploy in-database (native format) and third-party (ONNX format) models
* Supports classification, regression, clustering, and feature extraction models
* Pay only for actual scoring compute – no separate VM provisioning or management
Monitoring
* Data and model monitoring

## Documentation

[Oracle Machine Learning Services](https://docs.oracle.com/en/database/oracle/machine-learning/omlss/index.html)

#### Copyright (c) 2025 Oracle Corporation and/or its affilitiates.

###### [The Universal Permissive License (UPL), Version 1.0](https://oss.oracle.com/licenses/upl/)
