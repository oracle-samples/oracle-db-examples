# Spring AI Oracle Knowledge Base

## Oracle Vector Store

The Oracle vector store keeps document content, metadata, and vector embeddings in an Oracle Database table. Spring AI uses the store to add documents and run similarity search. The sample table is named SPRING_AI_ORACLE_SAMPLE_STORE.

## Embedding Model

The embedding model converts text into numeric vectors. This sample uses the Oracle database embedding model named ALL_MINILM_L12_V2. The model must be loaded in Oracle before the Java sample can generate embeddings.

## Document Chunking

Document chunking splits a large document into smaller pieces before embedding. The sample uses Oracle DBMS_VECTOR_CHAIN.UTL_TO_CHUNKS with word-based chunking. Smaller chunks help retrieval return focused context instead of an entire document.

## Wallet Connection

The sample connects to Oracle using a wallet-based JDBC URL. The environment variable ORACLE_JDBC_URL can point to MemoryStore_high and set TNS_ADMIN to the local Wallet_MemoryStore directory.

## Object Storage Model Loading

When the ONNX model is not already loaded in Oracle, the model file can be uploaded to OCI Object Storage. A pre-authenticated request URL allows DBMS_VECTOR.LOAD_ONNX_MODEL_CLOUD to download the ONNX file without database credentials.

## Search Query

At runtime, the program asks for a search query in the terminal. The query is embedded and compared with the stored chunk embeddings. The top results show the content chunks that are closest to the query.

## Table Reset Behavior

The sample currently removes the existing vector store table on each run. This behavior comes from removeExistingVectorStoreTable(true), which is useful for demos but should be disabled when preserving stored documents matters.
