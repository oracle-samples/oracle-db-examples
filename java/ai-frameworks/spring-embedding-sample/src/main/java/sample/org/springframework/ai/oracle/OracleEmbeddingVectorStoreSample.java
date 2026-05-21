/*
 * Copyright 2023-present the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package sample.org.springframework.ai.oracle;

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
import org.springframework.ai.session.DefaultSessionService;
import org.springframework.ai.session.SessionRepository;
import org.springframework.ai.session.SessionService;
import org.springframework.ai.session.advisor.SessionMemoryAdvisor;
import org.springframework.ai.session.jdbc.JdbcSessionRepository;
import org.springframework.ai.session.jdbc.OracleJdbcSessionRepositoryDialect;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.oracle.OracleVectorStore;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Scanner;
import javax.sql.DataSource;

/**
 * Runnable end-to-end sample for the Oracle document reader, Oracle splitter, Oracle
 * embedding model, and Oracle vector store.
 *
 * @author Spring AI Contributors
 */
public final class OracleEmbeddingVectorStoreSample {

	private static final String DEFAULT_MODEL = "ALL_MINILM_L12_V2";

	private static final int DEFAULT_DIMENSIONS = 384;

	private static final String TABLE_NAME = "SPRING_AI_ORACLE_SAMPLE_STORE";

	private static final String DEFAULT_SOURCE_DOC_RESOURCE = "sample-documents/oracle-sample.md";

	private static final String DEFAULT_SESSION_ID = "oracle-sample-session";

	private static final String DEFAULT_USER_ID = "oracle-sample-user";

	private static final String DEFAULT_OLLAMA_BASE_URL = "http://localhost:11434";

	private static final String DEFAULT_OLLAMA_CHAT_MODEL = "qwen3:8b";

	private static final int DEFAULT_OLLAMA_MAX_TOKENS = 150;

	private static final int DEFAULT_VECTORSTORE_ADD_BATCH_SIZE = 16;

	private static final String DEFAULT_CHUNK_BY = "vocabulary";

	private static final int DEFAULT_CHUNK_MAX = 80;

	private static final int DEFAULT_CHUNK_OVERLAP = 16;

	private static final String DEFAULT_CHUNK_SPLIT = "sentence";

	private static final String DEFAULT_CHUNK_VOCABULARY = "DOC_VOCAB_1 ";

	/**
	 * Utility class constructor.
	 */
	private OracleEmbeddingVectorStoreSample() {
	}

	/**
	 * Starts the interactive sample that ingests a source document, indexes chunks into
	 * Oracle Vector Store, and answers user questions with retrieved context.
	 *
	 * @param args application arguments (not used)
	 * @throws Exception if startup or runtime initialization fails
	 */
	public static void main(String[] args) throws Exception {
		try (Scanner scanner = new Scanner(System.in)) {
			DriverManagerDataSource dataSource = dataSource();
			JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);
			int dimensions = envInt("ORACLE_EMBEDDING_DIMENSIONS", DEFAULT_DIMENSIONS);
			String sessionId = env("ORACLE_SAMPLE_SESSION_ID", DEFAULT_SESSION_ID);
			SessionRepository sessionRepository = sessionRepository(dataSource);
			SessionService sessionService = DefaultSessionService.builder()
				.sessionRepository(sessionRepository)
				.build();
			SessionMemoryAdvisor sessionMemoryAdvisor = SessionMemoryAdvisor.builder(sessionService)
				.defaultUserId(DEFAULT_USER_ID)
				.build();
			ChatClient assistant = ChatClient.builder(ollamaChatModel())
				.defaultAdvisors(sessionMemoryAdvisor)
				.build();

			OracleEmbeddingModel embeddingModel = embeddingModel(dataSource, dimensions);
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

			System.out.printf("Loaded %d documents as %d chunks into %s.%n", documents.size(), chunks.size(),
					TABLE_NAME);
			System.out.printf("Chunking setup: by=%s, vocabulary=%s, max=%d, overlap=%d, split=%s%n",
					env("ORACLE_CHUNK_BY", DEFAULT_CHUNK_BY),
					env("ORACLE_CHUNK_VOCABULARY", DEFAULT_CHUNK_VOCABULARY),
					envInt("ORACLE_CHUNK_MAX", DEFAULT_CHUNK_MAX), envInt("ORACLE_CHUNK_OVERLAP", DEFAULT_CHUNK_OVERLAP),
					env("ORACLE_CHUNK_SPLIT", DEFAULT_CHUNK_SPLIT));
			String additionalPreferences = env("ORACLE_CHUNK_ADDITIONAL_PREFERENCES_JSON", "");
			if (StringUtils.hasText(additionalPreferences)) {
				System.out.printf("Additional chunk preferences: %s%n", additionalPreferences);
			}
			System.out.printf("Vector-store add batch size: %d%n", addBatchSize);
			System.out.printf("Embedding batching enabled: %s%n", envBoolean("ORACLE_EMBEDDING_BATCHING", false));
			System.out.printf("ONNX load on startup enabled: %s%n", envBoolean("ORACLE_ONNX_LOAD_ON_STARTUP", false));
			System.out.printf("Chat started with Ollama model %s.%n",
					env("OLLAMA_CHAT_MODEL", DEFAULT_OLLAMA_CHAT_MODEL));
			System.out.printf("Source document resource: %s%n",
					env("ORACLE_SOURCE_DOCUMENT_RESOURCE", DEFAULT_SOURCE_DOC_RESOURCE));
			System.out.printf("Oracle session id: %s%n", sessionId);
			System.out.println("Type 'exit' or 'quit' to stop.");

			while (true) {
				System.out.print("You: ");
				if (!scanner.hasNextLine()) {
					break;
				}

				String userInput = scanner.nextLine().trim();
				if (!StringUtils.hasText(userInput)) {
					continue;
				}
				if ("exit".equalsIgnoreCase(userInput) || "quit".equalsIgnoreCase(userInput)) {
					System.out.println("Bye.");
					break;
				}

				List<Document> results = vectorStore.similaritySearch(
						SearchRequest.builder().query(userInput).topK(3).similarityThresholdAll().build());
				try {
					String answer = answerWithRetrievedContext(assistant, sessionId, userInput, results);

					System.out.printf("Assistant: %s%n", answer);
					for (Document result : results) {
						System.out.printf("score=%s text=%s%n", result.getScore(), result.getText());
					}
				}
				catch (RuntimeException ex) {
					System.out.printf("Assistant request failed: %s%n", ex.getMessage());
					System.out.println("Check Ollama server/model and try lowering OLLAMA_MAX_TOKENS.");
				}
			}
		}
	}

	/**
	 * Adds chunk documents to the vector store in fixed-size batches.
	 *
	 * @param vectorStore the vector store instance
	 * @param chunks the chunk documents to add
	 * @param batchSize the number of chunks per insert batch
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
	 * Builds a chat response using retrieved context and session memory.
	 *
	 * @param assistant the configured chat client
	 * @param sessionId the session identifier for memory continuity
	 * @param userInput the user prompt
	 * @param results retrieved vector store documents
	 * @return assistant response text
	 */
	private static String answerWithRetrievedContext(ChatClient assistant, String sessionId, String userInput,
			List<Document> results) {
		return assistant.prompt()
			.system("""
					You are a helpful assistant.

					If the user is making small talk, greeting you, or asking a general conversational question,
					answer normally without requiring retrieved context.

					If the user asks about the Oracle sample, embeddings, vector store, document chunking,
					database tables, or the loaded documents, use the retrieved Oracle vector store context.

					If the user asks a document-specific question and the retrieved context is not enough,
					say that the Oracle vector store did not return enough context.

					Retrieved context:
					%s
					""".formatted(retrievedContext(results)))
			.user(userInput)
			.advisors(advisor -> advisor.param(SessionMemoryAdvisor.SESSION_ID_CONTEXT_KEY, sessionId)
				.param(SessionMemoryAdvisor.USER_ID_CONTEXT_KEY, DEFAULT_USER_ID))
			.call()
			.content();
	}

	/**
	 * Creates a JDBC-backed repository for chat sessions in Oracle.
	 *
	 * @param dataSource datasource used to persist sessions
	 * @return session repository implementation
	 */
	private static SessionRepository sessionRepository(DataSource dataSource) {
		return JdbcSessionRepository.builder()
			.dataSource(dataSource)
			.dialect(new OracleJdbcSessionRepositoryDialect())
			.build();
	}

	/**
	 * Formats retrieved vector-store chunks into a textual context block.
	 *
	 * @param results retrieved documents
	 * @return formatted context text for prompt injection
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
	 * Loads the source document from the classpath using the Oracle document reader.
	 *
	 * @param dataSource datasource used by the Oracle document reader
	 * @return loaded documents from the configured classpath resource
	 */
	private static List<Document> loadDocuments(DataSource dataSource) {
		String resourcePath = env("ORACLE_SOURCE_DOCUMENT_RESOURCE", DEFAULT_SOURCE_DOC_RESOURCE);
		Resource resource = new ClassPathResource(resourcePath);
		if (!resource.exists()) {
			throw new IllegalStateException(
					"Resource not found on classpath: " + resourcePath + " (add it under src/main/resources)");
		}
		OracleDocumentReader reader = OracleDocumentReader.builder(dataSource, resource)
			.preferences(OracleDocumentPreferences.builder().format("TEXT").build())
			.build();
		return reader.get();
	}

	/**
	 * Creates the Oracle document splitter with preferences sourced from environment
	 * variables.
	 *
	 * @param dataSource datasource used for Oracle chunking operations
	 * @return configured document splitter
	 */
	private static DocumentSplitter documentSplitter(DataSource dataSource) {
		String chunkBy = env("ORACLE_CHUNK_BY", DEFAULT_CHUNK_BY);
		OracleChunkingPreferences.Builder preferencesBuilder = OracleChunkingPreferences.builder()
			.by(chunkBy)
			.max(envInt("ORACLE_CHUNK_MAX", DEFAULT_CHUNK_MAX))
			.overlap(envInt("ORACLE_CHUNK_OVERLAP", DEFAULT_CHUNK_OVERLAP))
			.split(env("ORACLE_CHUNK_SPLIT", DEFAULT_CHUNK_SPLIT))
			.language("american")
			.normalize("all")
			.extended(true);

		if ("vocabulary".equalsIgnoreCase(chunkBy)) {
			preferencesBuilder.vocabulary(env("ORACLE_CHUNK_VOCABULARY", DEFAULT_CHUNK_VOCABULARY));
		}

		return DocumentSplitter.builder(dataSource).preferences(preferencesBuilder.build()).build();
	}


	/**
	 * Creates the Oracle embedding model and optionally configures ONNX load-on-startup.
	 *
	 * @param dataSource datasource used by the embedding model
	 * @param dimensions embedding dimensions
	 * @return configured embedding model
	 */
	private static OracleEmbeddingModel embeddingModel(DataSource dataSource, int dimensions) {
		String model = env("ORACLE_EMBEDDING_MODEL", DEFAULT_MODEL);
		OracleEmbeddingOptions options = OracleEmbeddingOptions.builder()
			.model(model)
			.dimensions(dimensions)
			.batching(envBoolean("ORACLE_EMBEDDING_BATCHING", false))
			.preferences(OracleEmbeddingPreferences.builder().provider("database").model(model).build())
			.build();

		boolean onnxLoadOnStartup = envBoolean("ORACLE_ONNX_LOAD_ON_STARTUP", false);
		if (!onnxLoadOnStartup) {
			return new OracleEmbeddingModel(dataSource, options);
		}

		String onnxDirectoryAlias = env("ORACLE_ONNX_DIRECTORY_ALIAS", "");
		String onnxFile = env("ORACLE_ONNX_FILE", "");
		String onnxUri = env("ORACLE_ONNX_URI", "");
		String onnxCredential = env("ORACLE_ONNX_CREDENTIAL", "");

		boolean hasLocalConfig = StringUtils.hasText(onnxDirectoryAlias) || StringUtils.hasText(onnxFile);
		boolean hasCloudConfig = StringUtils.hasText(onnxUri) || StringUtils.hasText(onnxCredential);
		if (hasLocalConfig && hasCloudConfig) {
			throw new IllegalStateException("Set either local ONNX config (ORACLE_ONNX_DIRECTORY_ALIAS/ORACLE_ONNX_FILE) "
					+ "or cloud ONNX config (ORACLE_ONNX_URI with optional ORACLE_ONNX_CREDENTIAL), not both.");
		}

		OracleEmbeddingModel.Builder builder = OracleEmbeddingModel.builder(dataSource)
			.defaultOptions(options)
			.initializeOnStartup(true)
			.onnxModelName(model);

		if (hasCloudConfig) {
			if (!StringUtils.hasText(onnxUri)) {
				throw new IllegalStateException("When ORACLE_ONNX_LOAD_ON_STARTUP=true and cloud mode is used, "
						+ "ORACLE_ONNX_URI is required.");
			}
			return builder.onnxCredential(StringUtils.hasText(onnxCredential) ? onnxCredential : null)
				.onnxUri(onnxUri)
				.build();
		}

		if (!StringUtils.hasText(onnxDirectoryAlias) || !StringUtils.hasText(onnxFile)) {
			throw new IllegalStateException("When ORACLE_ONNX_LOAD_ON_STARTUP=true, set local ONNX vars "
					+ "(ORACLE_ONNX_DIRECTORY_ALIAS and ORACLE_ONNX_FILE) or cloud ONNX vars "
					+ "(ORACLE_ONNX_URI with optional ORACLE_ONNX_CREDENTIAL).");
		}

		return builder.onnxDirectoryAlias(onnxDirectoryAlias).onnxFile(onnxFile).build();
	}

	/**
	 * Creates the Ollama chat model used by the assistant.
	 *
	 * @return configured chat model
	 */
	private static ChatModel ollamaChatModel() {
		String modelName = env("OLLAMA_CHAT_MODEL", DEFAULT_OLLAMA_CHAT_MODEL);
		OllamaChatOptions options = OllamaChatOptions.builder()
			.model(modelName)
			.disableThinking()
			.maxTokens(100)
			.build();

		return OllamaChatModel.builder()
			.ollamaApi(ollamaApi())
			.defaultOptions(options)
			.build();
	}

	/**
	 * Creates the Ollama API client.
	 *
	 * @return configured Ollama API client
	 */
	private static OllamaApi ollamaApi() {
		return OllamaApi.builder().baseUrl(env("OLLAMA_BASE_URL", DEFAULT_OLLAMA_BASE_URL)).build();
	}

	/**
	 * Creates the datasource from required Oracle JDBC environment variables.
	 *
	 * @return configured datasource
	 */
	private static DriverManagerDataSource dataSource() {
		DriverManagerDataSource dataSource = new DriverManagerDataSource();
		dataSource.setUrl(requiredEnv("ORACLE_JDBC_URL"));
		dataSource.setUsername(requiredEnv("ORACLE_USERNAME"));
		dataSource.setPassword(requiredEnv("ORACLE_PASSWORD"));
		return dataSource;
	}

	/**
	 * Resolves a required environment variable.
	 *
	 * @param name environment variable name
	 * @return trimmed environment value
	 * @throws IllegalStateException when the variable is missing or blank
	 */
	private static String requiredEnv(String name) {
		String value = System.getenv(name);
		if (!StringUtils.hasText(value)) {
			throw new IllegalStateException("Missing required environment variable: " + name);
		}
		return value.trim();
	}

	/**
	 * Resolves an optional environment variable with fallback default.
	 *
	 * @param name environment variable name
	 * @param defaultValue default value when not set
	 * @return trimmed environment value or the default
	 */
	private static String env(String name, String defaultValue) {
		String value = System.getenv(name);
		return StringUtils.hasText(value) ? value.trim() : defaultValue;
	}

	/**
	 * Resolves an optional integer environment variable with fallback default.
	 *
	 * @param name environment variable name
	 * @param defaultValue default value when not set
	 * @return parsed integer value or the default
	 */
	private static int envInt(String name, int defaultValue) {
		String value = System.getenv(name);
		return StringUtils.hasText(value) ? Integer.parseInt(value.trim()) : defaultValue;
	}

	/**
	 * Resolves an optional boolean environment variable with fallback default.
	 *
	 * @param name environment variable name
	 * @param defaultValue default value when not set
	 * @return parsed boolean value or the default
	 */
	private static boolean envBoolean(String name, boolean defaultValue) {
		String value = System.getenv(name);
		return StringUtils.hasText(value) ? Boolean.parseBoolean(value.trim()) : defaultValue;
	}

}
