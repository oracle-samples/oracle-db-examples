package rsi.example.common;

import oracle.rsi.ReactiveStreamsIngestion;

import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class RSIService {
  private ExecutorService workers;
  private ReactiveStreamsIngestion rsi;

  private String url;
  private String username;
  private String password;
  private String scheme;
  private Class<?> entity;

  public ReactiveStreamsIngestion start() {
    if (rsi != null) {
      return rsi;
    }

//    workers = Executors.newVirtualThreadPerTaskExecutor();
    workers = Executors.newFixedThreadPool(2);

    rsi =  ReactiveStreamsIngestion
        .builder()
        .url(url)
        .username(username)
        .password(password)
        .schema(scheme)
        .entity(entity)
        .executor(workers)
        .bufferInterval(Duration.ofMinutes(60))
        .build();

    return rsi;
  }

  public void stop() {
    if (rsi != null) {
      rsi.close();
    }

    if (workers != null) {
      workers.shutdown();
    }
  }

  public void setUrl(String url) {
    this.url = url;
  }

  public void setUsername(String username) {
    this.username = username;
  }

  public void setPassword(String password) {
    this.password = password;
  }

  public void setScheme(String scheme) {
    this.scheme = scheme;
  }

  public void setEntity(Class<?> entity) {
    this.entity = entity;
  }
}
