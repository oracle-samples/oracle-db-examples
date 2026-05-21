package sample.consumer;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.document.Document;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.ai.ollama.api.OllamaApi;
import org.springframework.ai.ollama.api.OllamaChatOptions;
import org.springframework.ai.oracle.chunking.DocumentSplitter;
import org.springframework.ai.oracle.chunking.OracleChunkingPreferences;
import org.springframework.ai.oracle.embedding.OracleEmbeddingModel;
import org.springframework.ai.oracle.embedding.OracleEmbeddingOptions;
import org.springframework.ai.oracle.embedding.OracleEmbeddingPreferences;
import org.springframework.ai.oracle.loader.OracleDocumentPreferences;
import org.springframework.ai.oracle.loader.OracleDocumentReader;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.oracle.OracleVectorStore;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.util.List;
import java.util.Scanner;

/**
 * This sample consumes spring-ai-oracle through Maven dependency only.
 */
public final class OracleDependencyVectorStoreSample {

    private static final String DEFAULT_EMBEDDING_PROVIDER = "ocigenai";

    private static final String DEFAULT_OCIGENAI_MODEL = "cohere.embed-english-light-v3.0";

    private static final int DEFAULT_DATABASE_DIMENSIONS = 384;

    private static final int DEFAULT_OCIGENAI_DIMENSIONS = 384;

    private static final String DEFAULT_OCIGENAI_CREDENTIAL_NAME = "OCI_CRED";

    private static final String DEFAULT_OCIGENAI_EMBED_URL = "https://inference.generativeai.us-chicago-1.oci.oraclecloud.com/20231130/actions/embedText";

    private static final String DEFAULT_OLLAMA_BASE_URL = "http://localhost:11434";

    private static final String DEFAULT_OLLAMA_CHAT_MODEL = "qwen3:8b";

    private static final String TABLE_NAME = "SPRING_AI_ORACLE_DEPENDENCY_SAMPLE_STORE";

    private static final String DEFAULT_SOURCE_DOC_RESOURCE = "sample-documents/oracle-sample.md";

    private static final int DEFAULT_VECTORSTORE_ADD_BATCH_SIZE = 16;

    /**
     * Prevents instantiation of this utility-style sample class.
     */
    private OracleDependencyVectorStoreSample() {
    }

    /**
     * Bootstraps the sample by loading documents, indexing chunks, and starting
     * an interactive question/answer loop backed by vector search plus chat.
     *
     * @param args CLI arguments (unused).
     * @throws Exception if initialization fails.
     */
    public static void main(String[] args) throws Exception {
        DriverManagerDataSource dataSource = dataSource();
        JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);

        String embeddingProvider = env("ORACLE_EMBEDDING_PROVIDER", DEFAULT_EMBEDDING_PROVIDER);
        int dimensions = envInt("ORACLE_EMBEDDING_DIMENSIONS", defaultDimensions(embeddingProvider));
        boolean showRetrievalDebug = envBoolean("ORACLE_SHOW_RETRIEVAL_DEBUG", false);

        OracleEmbeddingModel embeddingModel = embeddingModel(dataSource, embeddingProvider, dimensions);
        embeddingModel.afterPropertiesSet();

        OracleVectorStore vectorStore = OracleVectorStore.builder(jdbcTemplate, embeddingModel)
                .tableName(TABLE_NAME)
                .dimensions(dimensions)
                .initializeSchema(true)
                .removeExistingVectorStoreTable(true)
                .build();
        vectorStore.afterPropertiesSet();

        List<Document> documents = loadDocuments(dataSource);
        DocumentSplitter splitter = documentSplitter(dataSource);
        List<Document> chunks = splitter.split(documents);

        int addBatchSize = envInt("ORACLE_VECTORSTORE_ADD_BATCH_SIZE", DEFAULT_VECTORSTORE_ADD_BATCH_SIZE);
        addDocumentsInBatches(vectorStore, chunks, addBatchSize);

        ChatClient assistant = ChatClient.builder(ollamaChatModel()).build();

        System.out.printf("Loaded %d documents as %d chunks into %s.%n", documents.size(), chunks.size(), TABLE_NAME);
        System.out.printf("Embedding provider: %s%n", embeddingProvider);
        System.out.printf("Embedding model: %s%n", env("ORACLE_EMBEDDING_MODEL", defaultModel(embeddingProvider)));
        System.out.printf("Chat model: %s%n", env("OLLAMA_CHAT_MODEL", DEFAULT_OLLAMA_CHAT_MODEL));
        System.out.println("Type your question. Type 'exit' or 'quit' to stop.");

        try (Scanner scanner = new Scanner(System.in)) {
            while (true) {
                System.out.print("You: ");
                if (!scanner.hasNextLine()) {
                    break;
                }

                String query = scanner.nextLine().trim();
                if (!StringUtils.hasText(query)) {
                    continue;
                }
                if ("exit".equalsIgnoreCase(query) || "quit".equalsIgnoreCase(query)) {
                    System.out.println("Bye.");
                    break;
                }

                List<Document> results = vectorStore.similaritySearch(
                        SearchRequest.builder().query(query).topK(3).similarityThresholdAll().build());

                String answer;
                try {
                    answer = answerWithRetrievedContext(assistant, query, results);
                }
                catch (RuntimeException ex) {
                    if (results.isEmpty()) {
                        answer = "I couldn't generate a chat response right now, and no vector context was found.";
                    }
                    else {
                        answer = results.get(0).getText();
                    }
                }

                System.out.printf("Assistant: %s%n", answer);

                if (showRetrievalDebug) {
                    for (Document result : results) {
                        System.out.printf("score=%s text=%s%n", result.getScore(), result.getText());
                    }
                }
            }
        }
    }

    /**
     * Produces an assistant answer using retrieved vector-store context.
     *
     * @param assistant chat client used to generate the response.
     * @param userInput user question text.
     * @param results retrieved chunks to include in the system prompt.
     * @return generated assistant response text.
     */
    private static String answerWithRetrievedContext(ChatClient assistant, String userInput, List<Document> results) {
        return assistant.prompt()
                .system("""
                        You are a helpful assistant.

                        If the user asks a general conversational question (for example greetings, small talk,
                        casual questions, or non-Oracle topics), answer naturally without requiring retrieved context.

                        If the user asks about Oracle sample code, embeddings, vector stores, chunking,
                        database tables, or loaded documents, use the retrieved context below.

                        If the user asks a document-specific question and context is insufficient, say that clearly.

                        Retrieved context:
                        %s
                        """.formatted(retrievedContext(results)))
                .user(userInput)
                .call()
                .content();
    }

    /**
     * Formats retrieved chunks into a readable prompt context section.
     *
     * @param results retrieved documents from similarity search.
     * @return formatted context text, or a fallback message when no matches exist.
     */
    private static String retrievedContext(List<Document> results) {
        if (results.isEmpty()) {
            return "No matching chunks were returned.";
        }

        StringBuilder context = new StringBuilder();
        for (int i = 0; i < results.size(); i++) {
            Document result = results.get(i);
            context.append("Chunk ")
                    .append(i + 1)
                    .append(" score=")
                    .append(result.getScore())
                    .append(System.lineSeparator())
                    .append(result.getText())
                    .append(System.lineSeparator())
                    .append(System.lineSeparator());
        }
        return context.toString();
    }

    /**
     * Adds chunk documents to the vector store in fixed-size batches.
     *
     * @param vectorStore target vector store.
     * @param chunks chunk documents to index.
     * @param batchSize batch size for each add operation.
     */
    private static void addDocumentsInBatches(OracleVectorStore vectorStore, List<Document> chunks, int batchSize) {
        if (batchSize <= 0) {
            throw new IllegalStateException("ORACLE_VECTORSTORE_ADD_BATCH_SIZE must be greater than 0.");
        }

        for (int i = 0; i < chunks.size(); i += batchSize) {
            int end = Math.min(i + batchSize, chunks.size());
            vectorStore.add(chunks.subList(i, end));
        }
    }

    /**
     * Loads source documents from a classpath resource using Oracle document
     * reader preferences.
     *
     * @param dataSource database data source used by the reader.
     * @return loaded source documents.
     */
    private static List<Document> loadDocuments(DataSource dataSource) {
        String resourcePath = env("ORACLE_SOURCE_DOCUMENT_RESOURCE", DEFAULT_SOURCE_DOC_RESOURCE);
        Resource resource = new ClassPathResource(resourcePath);
        if (!resource.exists()) {
            throw new IllegalStateException(
                    "Resource not found on classpath: " + resourcePath + " (add it under src/main/resources)");
        }

        return OracleDocumentReader.builder(dataSource)
                .resource(resource)
                .preferences(OracleDocumentPreferences.builder().format("TEXT").build())
                .build()
                .get();
    }

    /**
     * Builds a document splitter using chunking configuration from environment
     * variables.
     *
     * @param dataSource database data source used for splitter creation.
     * @return configured document splitter.
     */
    private static DocumentSplitter documentSplitter(DataSource dataSource) {
        OracleChunkingPreferences options = OracleChunkingPreferences.builder()
                .by(env("ORACLE_CHUNK_BY", "words"))
                .max(envInt("ORACLE_CHUNK_MAX", 20))
                .overlap(envInt("ORACLE_CHUNK_OVERLAP", 5))
                .split(env("ORACLE_CHUNK_SPLIT", "sentence"))
                .language("american")
                .normalize("all")
                .extended(true)
                .build();

        return DocumentSplitter.builder(dataSource).preferences(options).build();
    }

    /**
     * Creates an Oracle embedding model configured for the selected provider.
     *
     * @param dataSource database data source used by the embedding model.
     * @param provider embedding provider name.
     * @param dimensions embedding vector dimensions.
     * @return configured embedding model.
     */
    private static OracleEmbeddingModel embeddingModel(DataSource dataSource, String provider, int dimensions) {
        String model = env("ORACLE_EMBEDDING_MODEL", defaultModel(provider));
        OracleEmbeddingPreferences.Builder preferences = OracleEmbeddingPreferences.builder()
                .provider(provider)
                .model(model);

        if ("ocigenai".equalsIgnoreCase(provider)) {
            preferences.credentialName(env("ORACLE_EMBEDDING_CREDENTIAL_NAME", DEFAULT_OCIGENAI_CREDENTIAL_NAME))
                    .url(env("ORACLE_EMBEDDING_URL", DEFAULT_OCIGENAI_EMBED_URL));
        }

        OracleEmbeddingOptions options = OracleEmbeddingOptions.builder()
                .model(model)
                .dimensions(dimensions)
                .proxy(env("ORACLE_EMBEDDING_PROXY", System.getenv("DEMO_PROXY")))
                .batching(envBoolean("ORACLE_EMBEDDING_BATCHING", true))
                .preferences(preferences.build())
                .build();

        return OracleEmbeddingModel.builder(dataSource).defaultOptions(options).build();
    }

    /**
     * Builds the Ollama-backed chat model used for conversational responses.
     *
     * @return configured chat model.
     */
    private static ChatModel ollamaChatModel() {
        String modelName = env("OLLAMA_CHAT_MODEL", DEFAULT_OLLAMA_CHAT_MODEL);
        OllamaChatOptions options = OllamaChatOptions.builder()
                .model(modelName)
                .disableThinking()
                .maxTokens(150)
                .build();

        return OllamaChatModel.builder().ollamaApi(ollamaApi()).defaultOptions(options).build();
    }

    /**
     * Creates the Ollama API client using the configured base URL.
     *
     * @return configured Ollama API client.
     */
    private static OllamaApi ollamaApi() {
        return OllamaApi.builder().baseUrl(env("OLLAMA_BASE_URL", DEFAULT_OLLAMA_BASE_URL)).build();
    }

    /**
     * Resolves the embedding dimensions for the selected provider.
     *
     * @param provider embedding provider name.
     * @return default dimension count.
     */
    private static int defaultDimensions(String provider) {
        return "ocigenai".equalsIgnoreCase(provider) ? DEFAULT_OCIGENAI_DIMENSIONS : DEFAULT_DATABASE_DIMENSIONS;
    }

    /**
     * Resolves the default model for the selected embedding provider.
     *
     * @param provider embedding provider name.
     * @return default embedding model identifier.
     */
    private static String defaultModel(String provider) {
        return DEFAULT_OCIGENAI_MODEL;
    }

    /**
     * Creates the JDBC data source from required Oracle connection environment
     * variables.
     *
     * @return configured driver manager data source.
     */
    private static DriverManagerDataSource dataSource() {
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setUrl(requiredEnv("ORACLE_JDBC_URL"));
        dataSource.setUsername(requiredEnv("ORACLE_USERNAME"));
        dataSource.setPassword(requiredEnv("ORACLE_PASSWORD"));
        return dataSource;
    }

    /**
     * Reads a required environment variable and fails fast when missing.
     *
     * @param name environment variable name.
     * @return trimmed environment variable value.
     */
    private static String requiredEnv(String name) {
        String value = System.getenv(name);
        if (!StringUtils.hasText(value)) {
            throw new IllegalStateException("Missing required environment variable: " + name);
        }
        return value.trim();
    }

    /**
     * Reads an optional environment variable and falls back to a default.
     *
     * @param name environment variable name.
     * @param defaultValue value used when the variable is unset or blank.
     * @return resolved string value.
     */
    private static String env(String name, String defaultValue) {
        String value = System.getenv(name);
        return StringUtils.hasText(value) ? value.trim() : defaultValue;
    }

    /**
     * Reads an optional integer environment variable.
     *
     * @param name environment variable name.
     * @param defaultValue value used when the variable is unset or blank.
     * @return resolved integer value.
     */
    private static int envInt(String name, int defaultValue) {
        String value = System.getenv(name);
        return StringUtils.hasText(value) ? Integer.parseInt(value.trim()) : defaultValue;
    }

    /**
     * Reads an optional boolean environment variable.
     *
     * @param name environment variable name.
     * @param defaultValue value used when the variable is unset or blank.
     * @return resolved boolean value.
     */
    private static boolean envBoolean(String name, boolean defaultValue) {
        String value = System.getenv(name);
        return StringUtils.hasText(value) ? Boolean.parseBoolean(value.trim()) : defaultValue;
    }
}
