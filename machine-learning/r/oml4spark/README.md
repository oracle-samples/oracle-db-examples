# OML4Spark-Tutorials

## Tutorials for OML4Spark (a.k.a. ORAAH) release 2.8.x
**The [Oracle Machine Learning for Spark][1] (OML4Spark) is a set of R packages and Java libraries**
**It provides several features:**
- An R interface for manipulating data stored in a local File System, HDFS, HIVE, Impala or JDBC sources, and creating Distributed Model Matrices across a Cluster of Hadoop Nodes in preparation for ML
- A general computation framework where users invoke parallel, distributed MapReduce jobs from R, writing custom mappers and reducers in R while also leveraging open source CRAN packages
- Parallel and distributed Machine Learning algorithms that take advantage of all the nodes of a Hadoop cluster for scalable, high performance modeling on big data. Functions use the expressive R formula object optimized for Spark parallel execution
ORAAH's custom LM/GLM/MLP NN algorithms on Spark scale better and run faster than the open-source Spark MLlib functions, but ORAAH provides interfaces to MLlib as well
- Core Analytics functionality halso available in a standalone Java library that can be used directly without the need of the R language, and can be called from any Java or Scala platform.


**The following are a list of demos containing R code for learning about (OML4Spark)** 
- Files on the current folder
  - Introduction to OML4Spark (oml4spark_tutorial_getting_started_with_hdfs.r)
  - Working with HIVE, IMPALA and Spark Data Frames (oml4spark_tutorial_getting_started_with_hive_impala_spark.r)
  - Function in R to visualize Hadoop Data in Apache Zeppelin z.show (oml4spark_function_zeppelin_visualization_z_show.r)
  - AutoML for Classification using Cross Validation with OML4Spark
    * Sample Execution of the Cross Validation (oml4spark_execute_cross_validation.r)
    * Function to run the Cross Validation (oml4spark_function_run_cross_validation.r)
    * Function to Create a Balanced input Dataset (oml4spark_function_create_balanced_input.r)
    * Function to run Variable Selection via GLM Logistic (oml4spark_function_variable_selection_via_glm.r)
    * Function to run Variable Selection via Singular Value Decomposition (oml4spark_function_variable_selection_via_pca.r)
    * Function to compute Confusion Matrix and statistics (oml4spark_function_confusion_matrix_in_spark.r)
    * Function to build all OML4Spark models (oml4spark_function_build_all_classification_models.r)

[1]:https://www.oracle.com/database/technologies/datawarehouse-bigdata/oml4spark.html

#### Copyright (c) 2020 Oracle Corporation and its affiliates

##### [The Universal Permissive License (UPL), Version 1.0](https://oss.oracle.com/licenses/upl/)

