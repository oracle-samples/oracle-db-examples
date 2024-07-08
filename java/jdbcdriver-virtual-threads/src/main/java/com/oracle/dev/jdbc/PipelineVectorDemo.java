/*
  Copyright (c) 2024, Oracle and/or its affiliates.

  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

package com.oracle.dev.jdbc;

import com.oracle.bmc.auth.AuthenticationDetailsProvider;
import com.oracle.bmc.auth.ConfigFileAuthenticationDetailsProvider;
import com.oracle.bmc.generativeaiinference.GenerativeAiInferenceAsyncClient;
import com.oracle.bmc.generativeaiinference.model.EmbedTextDetails;
import com.oracle.bmc.generativeaiinference.model.OnDemandServingMode;
import com.oracle.bmc.generativeaiinference.requests.EmbedTextRequest;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleType;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.Callable;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Flow;
import java.util.concurrent.StructuredTaskScope;
import java.util.concurrent.StructuredTaskScope.ShutdownOnFailure;
import java.util.concurrent.StructuredTaskScope.Subtask;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Gatherers;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;

import static java.nio.charset.StandardCharsets.UTF_8;

/**
 * <p>
 * This class contains code examples which use virtual threads, pipelined
 * database calls, and AI vector search. The examples will cover three different
 * operations:
 * <ol><li>
 *   The {@link #loadTable(Connection)} method executes pipelined batch inserts
 *   on virtual threads. The inserts will load a database table with text data.
 * </li><li>
 *   The {@link #updateTable(Connection)} method executes pipelined batch
 *   updates on virtual threads. The updates will store vector embeddings for
 *   the text data. The embeddings are requested from Oracle Cloud's Generative
 *   AI service.
 * </li><li>
 *   The {@link #searchTableText(Connection, List)} method executed pipelined SELECT
 *   queries on virtual threads. The queries use the VECTOR_DISTANCE function of
 *   Oracle Database to perform a similarity search against vector embeddings.
 * </li></ol>
 * </p><p>
 * These methods use the Structured Concurrency API, which is a preview feature
 * in JDK 22. The "--enable-preview" option must be provided when compiling and
 * running this code.
 * </p><p>
 * For Mac OS Users: Run with -Doracle.jdbc.disablePipeline=false to enable
 * pipelined database calls.
 * </p><p>
 * A key thing to note about this demo is how many threads all share one JDBC
 * connection, and use it to execute SQL operations concurrently. Normally, that
 * would not be possible: Synchronous APIs like
 * {@link PreparedStatement#execute()} block the calling the thread until all
 * previous SQL opeations have completed. Concurrent SQL is possible because
 * this demo uses pipelined database calls. Pipelined calls only available
 * through Oracle JDBC's Reactive Extensions API, with methods like
 * {@link OraclePreparedStatement#executeAsyncOracle()}.
 * </p>
 */
public class PipelineVectorDemo {

  /**
   * The maximum number of embeddings that can be requested in a single call to
   * the embedding endpoint.
   */
  private static final int MAX_EMBEDDINGS_REQUEST = 96;

  /** Profile name from $HOME/.oci/config */
  private static final String OCI_PROFILE =
    Optional.ofNullable(System.getenv("OCI_PROFILE"))
      .orElse("DEFAULT");

  /** OCI authentication details read from $HOME/.oci/config */
  private static final AuthenticationDetailsProvider OCI_AUTHENTICATION;

  /**
   * OCID of a compartment. Get this value from:
   * https://cloud.oracle.com/identity/compartments
   */
  private static final String COMPARTMENT_OCID;

  /**
   * OCID of an embedding model. Get this value from:
   * <pre>
   * oci generative-ai model-collection list-models --compartment-id {your-compartment-id}
   * </pre>
   */
  private static final String MODEL_ID;

  static {
    try {
      OCI_AUTHENTICATION =
        new ConfigFileAuthenticationDetailsProvider(OCI_PROFILE);

      MODEL_ID =
        Optional.ofNullable(System.getenv("MODEL_OCID"))
          .orElseThrow(() ->
            new RuntimeException(
              "MODEL_OCID must be set as an environment variable"));

      COMPARTMENT_OCID  =
        Optional.ofNullable(System.getenv("COMPARTMENT_OCID"))
          .orElseThrow(() ->
            new RuntimeException(
              "OCI_COMPARTMENT must be set as an environment variable"));
    }
    catch (Exception exception) {
      exception.printStackTrace();
      throw new IllegalStateException(exception);
    }
  }

  private final static String DB_URL = DatabaseConfig.getDbUrl();
  private final static String DB_USER = DatabaseConfig.getDbUser();
  private final static String DB_PASSWORD = DatabaseConfig.getDbPassword();

  public static void main(String[] args) throws Exception {
    try (
      Connection connection = DriverManager.getConnection(
        DB_URL, DB_USER, DB_PASSWORD);
      Statement statement = connection.createStatement();
      AutoCloseable dropTable = () -> statement.execute("DROP TABLE example");
    ) {

      // Create a table with columns to store text and the vector embedding of
      // the text.
      statement.execute(
        """
          CREATE TABLE example(
            id NUMBER GENERATED ALWAYS AS IDENTITY,
            text CLOB NOT NULL,
            embedding VECTOR(*, FLOAT32),
            PRIMARY KEY (id))
          """);

      // Insert text data into the data
      loadTable(connection);

      // Update the table with embeddings for the text data
      updateTable(connection);

      // Perform a similarity search for some search terms
      List<String> searchTerms = List.of(
        "Predatory behavior of cats",
        "Location of bears",
        "Best climate for dogs",
        "Animals in ancient times",
        "Beautiful birds",
        "Deadly fish",
        "Where the wild things are");

      List<String> searchResults = searchTableText(connection, searchTerms);

      for (int i = 0; i < searchResults.size(); i++) {
        System.out.println(searchTerms.get(i) + " :\n" + searchResults.get(i));
        System.out.println();
      }
    }
  }

  /**
   * Loads the example table with facts about animals. This method uses
   * the structured concurrency API (preview feature in JDK 22). Calls to
   * {@link StructuredTaskScope#fork(Callable)} execute concurrent batch INSERTs
   * into Oracle Database. The batch INSERTs are pipelined: This allows for
   * concurrent progress of MANY statements from ONE JDBC connection.
   */
  static void loadTable(Connection connection)
    throws IOException, InterruptedException, ExecutionException {

    long start = System.currentTimeMillis();

    // Stream text from a book about animals
    String bookUrl =
      "https://www.gutenberg.org/cache/epub/37959/pg37959.txt";
    try (
      Stream<String> paragraphStream = streamParagraphs(bookUrl);
      ShutdownOnFailure taskScope = new ShutdownOnFailure()) {

      // For every 100 paragraphs of text, execute a pipelined batch insert
      paragraphStream.gather(Gatherers.windowFixed(100))
        .forEach(paragraphs ->
          taskScope.fork(() -> pipelineBatchInsert(connection, paragraphs)));

      // Wait for all pipelined batch insert tasks to complete
      taskScope.join();
      taskScope.throwIfFailed();
    }
    finally {
      long duration = System.currentTimeMillis() - start;
      log(String.format("Table loaded in %.3f seconds", (duration / 1000f)));
    }
  }

  /**
   * Executes a pipelined batch INSERT using
   * {@link OraclePreparedStatement#executeBatchAsyncOracle()}. The async method
   * returns a Reactive Streams publisher, but this method blocks until the
   * Publisher completes and returns the result; Blocking is no problem with
   * virtual threads, because virtual threads are cheap!
   */
  static List<Long> pipelineBatchInsert(
    Connection connection, List<String> lines)
    throws SQLException {
    log("Inserting " + lines.size() + " rows...");

    try (PreparedStatement insert = connection.prepareStatement(
      "INSERT INTO example(text) VALUES(?)")) {

      for (String line : lines) {
        insert.setString(1, line);
        insert.addBatch();
      }

      // Pipeline the batch INSERT with executeBatchAsyncOracle
      Flow.Publisher<Long> publisher =
        insert.unwrap(OraclePreparedStatement.class)
          .executeBatchAsyncOracle();

      // No need for async/reactive callbacks. Just block the virtual thread.
      List<Long> updateCounts = new ArrayList<>();
      block(publisher, updateCounts::add);
      return updateCounts;
    }
    finally {
      log("Done inserting " + lines.size() + " rows");
    }
  }

  /**
   * Record class that stores the id and text column values of rows from the
   * example table
   */
  private record TextRecord(int id, String text) { }

  /**
   * Updates the example table with embeddings for it's text data. This method
   * uses the structured concurrency API (preview feature in JDK 22). Calls to
   * {@link StructuredTaskScope#fork(Callable)} execute concurrent batch UPDATEs
   * into Oracle Database. The batch UPDATEs are pipelined: This allows for
   * concurrent progress of MANY statements from ONE JDBC connection. The
   * UPDATEs store a vector embedding requested from Oracle Cloud's Generative
   * AI service.
   */
  static void updateTable(Connection connection)
    throws SQLException, InterruptedException, ExecutionException {

    long start = System.currentTimeMillis();
    try (ShutdownOnFailure taskScope = new ShutdownOnFailure()) {

     // Stream rows from pipelined fetches
     pipelineQuery(connection)
        .gather(Gatherers.windowFixed(MAX_EMBEDDINGS_REQUEST))
        .forEach(textRecords ->
          taskScope.fork(() -> {
            // Request embeddings from Oracle Cloud
            List<String> texts =
              textRecords.stream().map(TextRecord::text).toList();
            List<float[]> embeddings = requestEmbeddings(texts);

            // Pipeline batch updates
            return pipelineBatchUpdate(connection, textRecords, embeddings);
          }));

      taskScope.join();
      taskScope.throwIfFailed();
    }
    finally {
      long duration = System.currentTimeMillis() - start;
      log(String.format("Table updated in %.3f seconds", (duration / 1000f)));
    }
  }

  /**
   * Executes a SELECT query and pipelines row fetches using
   * {@link OracleResultSet#publisherOracle(Function)}. That method returns a
   * Reactive Streams publisher, but this method does NOT use reactive
   * callbacks, nor does it NOT return a Publisher (which would force the caller
   * to also use reactive callbacks!). Instead, this method assumes it is
   * executing on a virtual thread, so it is ok to block it. This method returns
   * a {@link Stream} which is generated by blocking for row data from the
   * Publisher.
   */
  static Stream<TextRecord> pipelineQuery(Connection connection)
    throws SQLException {

    PreparedStatement query = connection.prepareStatement("""
      SELECT id, text
      FROM example
      WHERE embedding IS NULL
      """);
    query.closeOnCompletion();

    // Pipeline row fetches using publisherOracle
    Flow.Publisher<TextRecord> publisher =
      query.executeQuery()
        .unwrap(OracleResultSet.class)
        .publisherOracle(row -> {
          try {
            return new TextRecord(
              row.getObject("id", Integer.class),
              row.getObject("text", String.class));
          }
          catch (SQLException sqlException) {
            throw new RuntimeException(sqlException);
          }
        });

    return stream(publisher);
  }

  /**
   * Executes a pipelined batch UPDATE using
   * {@link OraclePreparedStatement#executeBatchAsyncOracle()}. The async method
   * returns a Reactive Streams publisher, but this method does NOT use reactive
   * callbacks, nor does it NOT return a Publisher (which would force the caller
   * to also use reactive callbacks!). Instead, this method assumes it is
   * executing on a virtual thread, so it is ok to block it. This method blocks
   * until the Publisher completes, and then synchronously returns the update
   * counts.
   */
  static List<Long> pipelineBatchUpdate(
    Connection connection, List<TextRecord> textRecords,
    List<float[]> embeddings)
    throws SQLException {
    log("Updating " + textRecords.size() + " rows...");

    try (PreparedStatement update = connection.prepareStatement("""
      UPDATE example
      SET embedding = ?
      WHERE id = ?
      """)) {

      Iterator<float[]> embeddingsIterator = embeddings.iterator();

      // Batch update the table with the embeddings
      for (TextRecord textRecord : textRecords) {
        float[] embedding = embeddingsIterator.next();
        update.setObject(1, embedding, OracleType.VECTOR);
        update.setInt(2, textRecord.id);
        update.addBatch();
      }

      Flow.Publisher<Long> publisher =
        update.unwrap(OraclePreparedStatement.class).executeBatchAsyncOracle();

      // No need for async/reactive callbacks. Just block the virtual thread.
      List<Long> updateCounts = new ArrayList<>();
      block(publisher, updateCounts::add);
      return updateCounts;
    }
    finally {
      log("Done updating " + textRecords.size() + " rows");
    }
  }

  /**
   * <p>
   * Searches the example table for facts about animals. This method uses
   * the structured concurrency API (preview feature in JDK 22). Calls to
   * {@link StructuredTaskScope#fork(Callable)} execute concurrent SELECT
   * queries against Oracle Database. The queries are pipelined: This allows for
   * concurrent progress of MANY statements from ONE JDBC connection.
   * </p><p>
   * The input search terms are converted into vector embeddings using Oracle
   * Cloud's Generative AI service.
   * </p>
   */
  static List<String> searchTableText(
    Connection connection, List<String> searchTerms)
    throws ExecutionException, InterruptedException {

    try (ShutdownOnFailure taskScope = new ShutdownOnFailure()) {

      List<Subtask<List<String>>> searchTasks =
        searchTerms.stream()
          .gather(Gatherers.windowFixed(MAX_EMBEDDINGS_REQUEST))
          .map(gatheredSearchTerms ->
            taskScope.fork(() -> {
              // Request embeddings, and pipeline SELECT queries which perform
              // a similarity search.
              List<float[]> embeddings = requestEmbeddings(gatheredSearchTerms);
              return searchTableEmbeddings(connection, embeddings);
            }))
          .toList();

      taskScope.join();
      taskScope.throwIfFailed();

      return searchTasks.stream()
        .map(Subtask::get)
        .flatMap(List::stream)
        .toList();
    }
  }

  /**
   * Searches the example table for facts about animals. This method uses
   * the structured concurrency API (preview feature in JDK 22). Calls to
   * {@link StructuredTaskScope#fork(Callable)} execute concurrent SELECT
   * queries against Oracle Database. The queries are pipelined: This allows for
   * concurrent progress of MANY statements from ONE JDBC connection.
   */
  static List<String> searchTableEmbeddings(
    Connection connection, List<float[]> embeddings)
    throws InterruptedException, ExecutionException {

    try (ShutdownOnFailure taskScope = new ShutdownOnFailure()) {

      List<Subtask<String>> searchTasks =
        embeddings.stream()
          .map(embedding ->
            taskScope.fork(() -> pipelineSearchQuery(connection, embedding)))
          .toList();

      taskScope.join();
      taskScope.throwIfFailed();

      return searchTasks.stream()
        .map(Subtask::get)
        .toList();
    }
  }

  /**
   * <p>
   * Executes a pipelined SELECT query using
   * {@link OraclePreparedStatement#executeQueryAsyncOracle()}. The async method
   * returns a Reactive Streams publisher, but this method blocks until the
   * Publisher completes and returns the result; Blocking is no problem with
   * virtual threads, because virtual threads are cheap!
   * </p><p>
   * The SELECT query uses the VECTOR_DISTANCE function of Oracle Database to
   * perform a similarity search.
   * </p>
   */
  static String pipelineSearchQuery(Connection connection, float[] embedding)
    throws SQLException {
    try (
      PreparedStatement query = connection.prepareStatement(
        """
        SELECT text
        FROM example
        ORDER BY VECTOR_DISTANCE(embedding, ?, COSINE)
        FETCH APPROX FIRST 1 ROW ONLY
        """
      )) {

      // Bind an embedding as VECTOR data
      query.setObject(1, embedding, OracleType.VECTOR);

      // Execute a pipelined SQL query
      Flow.Publisher<OracleResultSet> queryPublisher =
        query.unwrap(OraclePreparedStatement.class)
          .executeQueryAsyncOracle();

      // Block for Publisher completion
      ResultSet resultSet = join(queryPublisher);

      // Return the similarity search result
      resultSet.next();
      return resultSet.getString(1);
    }
  }


  /**
   * Requests vector embeddings from Oracle Cloud's Generative AI service.
   */
  static List<float[]> requestEmbeddings(List<String> texts)
    throws ExecutionException, InterruptedException {

    GenerativeAiInferenceAsyncClient.Builder builder =
      GenerativeAiInferenceAsyncClient.builder();

    try (var client = builder.build(OCI_AUTHENTICATION)) {

      // Max tokens is 512. Truncate strings which may be larger.
      texts =
        texts.stream()
          .map(text ->
            text.length() > 512 ? text.substring(0, 512) : text)
          .toList();

      EmbedTextDetails details =
        EmbedTextDetails.builder()
          .inputs(texts)
          .compartmentId(COMPARTMENT_OCID)
          .servingMode(OnDemandServingMode.builder()
            .modelId(MODEL_ID)
            .build())
          .build();

      EmbedTextRequest request =
        EmbedTextRequest.builder()
          .embedTextDetails(details)
          .build();

      log("Requesting " + texts.size() + " embeddings from Oracle Cloud...");
      return client.embedText(request, null)
        .get()
        .getEmbedTextResult()
        .getEmbeddings()
        .stream()
        .map(embedding -> {
          float[] floatArray = new float[embedding.size()];
          for (int i = 0; i < floatArray.length; i++) {
            floatArray[i] = embedding.get(i);
          }
          return floatArray;
        })
        .toList();
    }
    finally {
      log("Done requesting " + texts.size() + " embeddings from Oracle Cloud");
    }
  }

  /**
   * Streams paragraphs of text from a remote URL.
   */
  static Stream<String> streamParagraphs(String urlString) throws IOException {
    URL url = new URL(urlString);
    Object content = url.getContent();

    if (!(content instanceof InputStream)) {
      throw new IllegalStateException(
        "Unexpected content: " + content.getClass());
    }

    BufferedReader reader =
      new BufferedReader(new InputStreamReader((InputStream)content, UTF_8));

    return Stream.generate(() -> {
        try {
          StringBuilder paragraphBuilder = new StringBuilder();
          do {
            String line = reader.readLine();

            if (line == null) {
              reader.close();
              return null;
            }

            if (line.isBlank())
              break;

            paragraphBuilder.append(line).append('\n');
          } while (true);

          return paragraphBuilder.toString();
        }
        catch (IOException exception) {
          throw new RuntimeException(exception);
        }
      })
      .takeWhile(Objects::nonNull)
      .filter(Predicate.not(String::isBlank))
      .filter(paragraph -> paragraph.length() > 50)
      .onClose(() -> {
        try {
          reader.close();
        }
        catch (IOException ioException) {
          throw new RuntimeException(ioException);
        }
      });
  }

  /**
   * Blocks until a publisher emits a value, and then returns the value. This is
   * a helper method to transition from a Reactive Streams programming model
   * into a synchronous programming model. This transition is suitable for
   * virtual threads.
   */
  static <T> T join(Flow.Publisher<T> publisher) {

    // Complete this future with the result from a Publisher
    CompletableFuture<T> completableFuture = new CompletableFuture<>();

    // Subscribe to the Publisher
    publisher.subscribe(new Flow.Subscriber<T>() {

      @Override
      public void onSubscribe(Flow.Subscription subscription) {
        subscription.request(1);
      }

      @Override
      public void onNext(T item) {
        // Complete the future with a value
        completableFuture.complete(item);
      }

      @Override
      public void onError(Throwable throwable) {
        // Complete the future with an error
        completableFuture.completeExceptionally(throwable);
      }

      @Override
      public void onComplete() {
        // Complete the future with no value (null)
        completableFuture.complete(null);
      }
    });

    // Block for a result from the Publisher
    return completableFuture.join();
  }

  /**
   * Blocks while a publisher emits values, feeding each value to a Consuemr,
   * and then returning after the last value is emitted. This is a helper method
   * to transition from a Reactive Streams programming model into a
   * synchronous programming model. This transition is suitable for virtual
   * threads.
   */
  static <T> void block(Flow.Publisher<T> publisher, Consumer<T> consumer) {

    // Complete this future with the result from a Publisher
    CompletableFuture<T> completableFuture = new CompletableFuture<>();

    // Subscribe to the Publisher
    publisher.subscribe(new Flow.Subscriber<T>() {

      @Override
      public void onSubscribe(Flow.Subscription subscription) {
        subscription.request(Long.MAX_VALUE);
      }

      @Override
      public void onNext(T item) {
        consumer.accept(item);
      }

      @Override
      public void onError(Throwable throwable) {
        // Complete the future with an error
        completableFuture.completeExceptionally(throwable);
      }

      @Override
      public void onComplete() {
        // Complete the future with no value (null)
        completableFuture.complete(null);
      }
    });

    // Block for a result from the Publisher
    completableFuture.join();
  }

  /**
   * Streams values from a publisher, blocking while it emits values. This is
   * a helper method to transition from a Reactive Streams programming model
   * into a synchronous programming model. This transition is suitable for
   * virtual threads.
   */
  static <T> Stream<T> stream(Flow.Publisher<T> publisher) {
    Iterable<T> iterable = () -> iterate(publisher);
    return StreamSupport.stream(iterable.spliterator(), false);
  }

  /**
   * Iterates over values from a publisher, blocking while it emits values. This
   * is a helper method to transition from a Reactive Streams programming model
   * into a synchronous programming model. This transition is suitable for
   * virtual threads.
   */
  static <T> Iterator<T> iterate(Flow.Publisher<T> publisher) {

    class PublisherIterator implements Flow.Subscriber<T>, Iterator<T> {

      /** Completed with an asynchronous onSubscribe(Subscription) call */
      final CompletableFuture<Flow.Subscription> subscription =
        new CompletableFuture<>();

      /** Completed with an asynchronous onComplete or onError call */
      final CompletableFuture<Void> completion = new CompletableFuture<>();

      /** Set to non-null by hasNext(), set back to null by next() */
      CompletableFuture<T> next = null;

      @Override
      public void onSubscribe(Flow.Subscription subscription) {
        this.subscription.complete(subscription);
      }

      @Override
      public void onNext(T item) {
        next.complete(item);
      }

      @Override
      public void onError(Throwable throwable) {
        completion.completeExceptionally(throwable);
      }

      @Override
      public void onComplete() {
        completion.complete(null);
      }

      @Override
      public boolean hasNext() {
        // Check if next was already completed by onNext
        if (next != null && next.isDone())
          return true;

        // Request for next to be completed with onNext
        next = new CompletableFuture<>();
        subscription.join().request(1L);

        // Wait for next to be completed an onNext, or for completion to be
        // completed with onComplete or onError. A CompletionException is thrown
        // if completed with onError.
        CompletableFuture.anyOf(next, completion).join();

        // Check if next was completed by onNext. If not, then completion was
        // completed by onComplete.
        return next.isDone();
      }

      @Override
      public T next() {
        if (!hasNext())
          throw new NoSuchElementException();

        T next = this.next.join();
        this.next = null;
        return next;
      }
    }

    PublisherIterator subscriberator = new PublisherIterator();
    publisher.subscribe(subscriberator);
    return subscriberator;
  }

  /** Prints a message to the standard output stream */
  static void log(String message) {
    System.out.println(Thread.currentThread() + " : " + message);
  }

}
