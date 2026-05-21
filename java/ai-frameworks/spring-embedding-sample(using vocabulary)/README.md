# Spring AI Oracle Dependency Sample

This project is a runnable end-to-end Retrieval-Augmented Generation (RAG) sample using Oracle Database + Spring AI.

It demonstrates how to:

- Load documents with `OracleDocumentReader`
- Split documents into chunks with `DocumentSplitter`
- Generate embeddings with `OracleEmbeddingModel`
- Store and search vectors with `OracleVectorStore`
- Answer user questions with Ollama (`ChatClient`) using retrieved context
- Keep chat memory in Oracle with `spring-ai-session-jdbc`

The sample is dependency-driven: Oracle chunking/embedding/loader implementations are consumed from Maven dependencies in `pom.xml`.

## High-Level Flow

1. Connect to Oracle DB with JDBC (`ORACLE_JDBC_URL`, `ORACLE_USERNAME`, `ORACLE_PASSWORD`).
2. Build the Oracle embedding model using `ORACLE_EMBEDDING_MODEL` and dimensions.
3. Optionally load ONNX at startup (one-time) if enabled.
4. Create/reset Oracle vector store table (`SPRING_AI_ORACLE_SAMPLE_STORE`).
5. Read source document from classpath (`sample-documents/oracle-sample.md` by default).
6. Chunk documents using Oracle chunking preferences.
7. Embed and insert chunks into vector store.
8. Accept user question from terminal.
9. Run similarity search (`topK=3`) and inject retrieved chunks into prompt.
10. Send prompt to Ollama and print answer + retrieval debug lines.

## Main Components

- Main class: `src/main/java/sample/org/springframework/ai/oracle/OracleEmbeddingVectorStoreSample.java`
- Default source document: `src/main/resources/sample-documents/oracle-sample.md`
- Maven build and dependencies: `pom.xml`

Core libraries used:

- `org.springframework.ai:spring-ai-oracle`
- `org.springframework.ai:spring-ai-oracle-store`
- `org.springframework.ai:spring-ai-client-chat`
- `org.springframework.ai:spring-ai-ollama`
- `org.springaicommunity:spring-ai-session-jdbc`

## Prerequisites

- JDK 17+
- Maven 3.9+
- Oracle Database with vector features available
- Oracle user with permissions to create/use vector store objects
- Ollama running locally (default: `http://localhost:11434`)
- Chat model pulled in Ollama (default: `qwen3:8b`)
- Session tables required by `spring-ai-session-jdbc` must exist in your Oracle schema

If using ONNX initialization at startup, Oracle must have access to an ONNX file through either:

- local Oracle directory alias + file name
- cloud URI (with optional Oracle credential)

## Environment Variables

### Required

- `ORACLE_JDBC_URL`: Oracle JDBC URL
- `ORACLE_USERNAME`: DB user
- `ORACLE_PASSWORD`: DB password

### Optional (with defaults)

- `ORACLE_EMBEDDING_MODEL` (default: `ALL_MINILM_L12_V2`)
- `ORACLE_EMBEDDING_DIMENSIONS` (default: `384`)
- `ORACLE_EMBEDDING_BATCHING` (default: `false`)
- `ORACLE_VECTORSTORE_ADD_BATCH_SIZE` (default: `16`)
- `ORACLE_SOURCE_DOCUMENT_RESOURCE` (default: `sample-documents/oracle-sample.md`)
- `ORACLE_CHUNK_BY` (default: `words`)
- `ORACLE_CHUNK_MAX` (default: `80`)
- `ORACLE_CHUNK_OVERLAP` (default: `16`)
- `ORACLE_CHUNK_SPLIT` (default: `sentence`)
- `ORACLE_SAMPLE_SESSION_ID` (default: `oracle-sample-session`)
- `OLLAMA_BASE_URL` (default: `http://localhost:11434`)
- `OLLAMA_CHAT_MODEL` (default: `qwen3:8b`)

### ONNX Startup Initialization Controls

- `ORACLE_ONNX_LOAD_ON_STARTUP` (default: `false`)
- `ORACLE_ONNX_DIRECTORY_ALIAS` (required in local load mode)
- `ORACLE_ONNX_FILE` (required in local load mode)
- `ORACLE_ONNX_URI` (required in cloud load mode)
- `ORACLE_ONNX_CREDENTIAL` (optional in cloud load mode; can be omitted for pre-authenticated URLs)

## ONNX Behavior (Important)

This sample intentionally supports a one-time ONNX load strategy.

- If `ORACLE_ONNX_LOAD_ON_STARTUP=false`, `embeddingModel.afterPropertiesSet()` does not load ONNX.
- If `ORACLE_ONNX_LOAD_ON_STARTUP=true`, choose exactly one load mode:
  - Local mode: set `ORACLE_ONNX_DIRECTORY_ALIAS` and `ORACLE_ONNX_FILE`.
  - Cloud mode: set `ORACLE_ONNX_URI` and optionally `ORACLE_ONNX_CREDENTIAL`.
- Do not set local and cloud ONNX variables together in the same run.
- Recommended practice:
  1. Run once with `ORACLE_ONNX_LOAD_ON_STARTUP=true` to register/load the model.
  2. Run afterwards with `ORACLE_ONNX_LOAD_ON_STARTUP=false` to avoid reloading each startup.

Example one-time ONNX local load:

```bash
export ORACLE_ONNX_LOAD_ON_STARTUP=true
export ORACLE_ONNX_DIRECTORY_ALIAS=MY_ONNX_DIR
export ORACLE_ONNX_FILE=all_minilm_l12_v2.onnx
```

Example one-time ONNX cloud load:

```bash
export ORACLE_ONNX_LOAD_ON_STARTUP=true
export ORACLE_ONNX_URI='https://objectstorage.../all_minilm_l12_v2.onnx'
export ORACLE_ONNX_CREDENTIAL='OCI_CRED'
```

For a pre-authenticated URL, `ORACLE_ONNX_CREDENTIAL` can be omitted.

Then normal runs:

```bash
export ORACLE_ONNX_LOAD_ON_STARTUP=false
```

## Quick Start

Set minimum required env vars:

```bash
export ORACLE_JDBC_URL='jdbc:oracle:thin:@...'
export ORACLE_USERNAME='...'
export ORACLE_PASSWORD='...'
```

Optional Ollama overrides:

```bash
export OLLAMA_BASE_URL='http://localhost:11434'
export OLLAMA_CHAT_MODEL='qwen3:8b'
```

Run:

```bash
mvn exec:java
```

Build only:

```bash
mvn -Dmaven.test.skip=true compile
```

## Runtime Output and Interaction

At startup the sample prints:

- Number of loaded documents and resulting chunks
- Chunking configuration in use
- Embedding batching status
- Chat model and source document path
- Session id used for memory

Then it enters an interactive loop:

- Type a question and press Enter
- Type `exit` or `quit` to stop

For each question:

- Similarity search returns top 3 chunks
- Retrieved chunks are injected into system prompt
- Ollama generates final answer
- Result chunk scores/text are printed

## Session Memory

The sample configures:

- `JdbcSessionRepository` with `OracleJdbcSessionRepositoryDialect`
- `DefaultSessionService`
- `SessionMemoryAdvisor`

This allows cross-turn memory in the chat flow using:

- session id: `ORACLE_SAMPLE_SESSION_ID` (or default)
- user id: fixed default `oracle-sample-user`

## Current Demo-Oriented Table Reset Behavior

The vector store is built with:

- `initializeSchema(true)`
- `removeExistingVectorStoreTable(true)`

Meaning the vector table is recreated each run for demo convenience.

If you want persistence between runs, change `removeExistingVectorStoreTable(true)` to `false` in the sample class.

## Common Customizations

- Change document source: set `ORACLE_SOURCE_DOCUMENT_RESOURCE`
- Tune chunk size/overlap: set `ORACLE_CHUNK_MAX`, `ORACLE_CHUNK_OVERLAP`
- Tune ingestion speed: set `ORACLE_VECTORSTORE_ADD_BATCH_SIZE`
- Change embedding model/dimensions: set `ORACLE_EMBEDDING_MODEL`, `ORACLE_EMBEDDING_DIMENSIONS`
- Change chat model: set `OLLAMA_CHAT_MODEL`

## Troubleshooting

- Error: `Missing required environment variable`
  - Ensure required DB env vars are exported in the same shell.
- Error when `ORACLE_ONNX_LOAD_ON_STARTUP=true`
  - Set either local vars (`ORACLE_ONNX_DIRECTORY_ALIAS`, `ORACLE_ONNX_FILE`) or cloud vars (`ORACLE_ONNX_URI`, optional `ORACLE_ONNX_CREDENTIAL`), but not both.
- No answer from assistant
  - Verify Ollama is running and the selected model is available.
- Empty/weak retrieval
  - Check chunking configuration and embedding model dimensions.
- Data disappears between runs
  - Expected with `removeExistingVectorStoreTable(true)`.

## Notes

- This sample is intended for local experimentation and learning.
- For production usage, add stronger error handling, secure secret management, and persistence-friendly table lifecycle settings.
