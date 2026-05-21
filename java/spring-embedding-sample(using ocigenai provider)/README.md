# Oracle Dependency Consumer Sample

This module is a separate consumer app. It uses Spring AI Oracle classes through Maven dependency (no copied local classes).

## 1) Build and install the library artifact

From the Spring AI Oracle project/module that produces `org.springframework.ai:spring-ai-oracle`:

```bash
mvn -DskipTests install
```

## 2) Configure JDBC environment

```bash
export ORACLE_JDBC_URL='jdbc:oracle:thin:@...'
export ORACLE_USERNAME='...'
export ORACLE_PASSWORD='...'
```

## 3) Configure `ocigenai` provider (required)

The sample uses Oracle DB `DBMS_VECTOR_CHAIN` with provider `ocigenai`.

### 3.1 Create DB credential

Connect as the same schema user used by `ORACLE_USERNAME`, then create credential `OCI_CRED`:

```sql
DECLARE
  jo json_object_t;
BEGIN
  jo := json_object_t();
  jo.put('user_ocid', 'ocid1.user...');
  jo.put('tenancy_ocid', 'ocid1.tenancy...');
  jo.put('compartment_ocid', 'ocid1.compartment...');
  jo.put('fingerprint', 'xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx');
  jo.put('private_key', '...private key content...');

  DBMS_VECTOR_CHAIN.CREATE_CREDENTIAL(
    credential_name => 'OCI_CRED',
    params => json(jo.to_string)
  );
END;
/
```

If credential is created in another schema, use `SCHEMA.OCI_CRED` in env var `ORACLE_EMBEDDING_CREDENTIAL_NAME`.


## 4) Set `ocigenai` runtime env vars

```bash
export ORACLE_EMBEDDING_PROVIDER='ocigenai'
export ORACLE_EMBEDDING_CREDENTIAL_NAME='OCI_CRED'
export ORACLE_EMBEDDING_URL='https://inference.generativeai.eu-amsterdam-1.oci.oraclecloud.com/20231130/actions/embedText'
export ORACLE_EMBEDDING_MODEL='cohere.embed-english-light-v3.0'
export ORACLE_EMBEDDING_DIMENSIONS='384'
```

Optional:

```bash
export ORACLE_EMBEDDING_PROXY='http://proxy:8080'
export ORACLE_VECTORSTORE_ADD_BATCH_SIZE='16'
export ORACLE_CHUNK_BY='words'
```

## 5) Chat response setup (optional but recommended)

This sample uses Ollama for natural conversational responses:

```bash
ollama serve
ollama pull qwen3:8b
export OLLAMA_BASE_URL='http://localhost:11434'
export OLLAMA_CHAT_MODEL='qwen3:8b'
```

To print retrieval debug chunks/scores each turn:

```bash
export ORACLE_SHOW_RETRIEVAL_DEBUG='true'
```

## 6) Run the sample

```bash
mvn -DskipTests exec:java
```

Type questions in the console. Type `exit` or `quit` to stop.

## Version note

`pom.xml` defaults to:

- `org.springframework.ai:spring-ai-oracle:2.0.0-SNAPSHOT`

If your built artifact version is different, update `spring.ai.oracle.version` in `pom.xml`.
