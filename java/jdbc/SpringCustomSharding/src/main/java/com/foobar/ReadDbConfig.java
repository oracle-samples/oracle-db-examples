/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

 package com.foobar;

import com.foobar.appschema.repo.ReadCustomerRepository;
import com.foobar.appschema.repo.ReadOrderRepository;
import com.foobar.foo.repo.ReadFooRepository;
import jakarta.persistence.EntityManagerFactory;
import javax.sql.DataSource;

import oracle.jdbc.OracleType;
import oracle.jdbc.pool.OracleShardingKeyBuilderImpl;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.FilterType;
import org.springframework.core.env.Environment;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.jdbc.datasource.ShardingKeyDataSourceAdapter;
import org.springframework.jdbc.datasource.ShardingKeyProvider;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import oracle.ucp.jdbc.PoolDataSource;

import java.sql.SQLException;
import java.sql.ShardingKey;
import java.time.Duration;
import java.util.Map;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.foobar", // Same package
        entityManagerFactoryRef = "readEntityManagerFactory",
        transactionManagerRef = "readTransactionManager",
        includeFilters = {
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = ReadFooRepository.class),
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = ReadCustomerRepository.class),
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = ReadOrderRepository.class),
        }
)
public class ReadDbConfig {
  private static final Logger log = LoggerFactory.getLogger(ReadDbConfig.class);
    
  @Autowired
  private Environment environment;

  @Bean
  @ConfigurationProperties("read.datasource")
  public DataSourceProperties readDataSourceProperties() {
    return new DataSourceProperties();
  }

  @Bean(name = "readDataSource")
  public DataSource dataSource(ShardingKeyProvider readShardingKeyProvider) throws SQLException {
    PoolDataSource dataSource = readDataSourceProperties()
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    dataSource.setConnectionProperties(new Properties());
    dataSource.setDataSourceName("readDataSource");
    dataSource.setConnectionPoolName("ReadPool");
    dataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
    dataSource.setMinPoolSize(0);
    dataSource.setInitialPoolSize(0);
    dataSource.setMaxPoolSize(20);
    dataSource.setMaxConnectionsPerShard(5);
    dataSource.setConnectionWaitDuration(Duration.ofSeconds(30));
    dataSource.setValidateConnectionOnBorrow(true);
    String poolName = dataSource.getConnectionPoolName();
    String ons = dataSource.getONSConfiguration();
    return new ShardingKeyDataSourceAdapter(dataSource, readShardingKeyProvider);
  }

  // Read EntityManagerFactory
  @Bean(name = "readEntityManagerFactory")
  public LocalContainerEntityManagerFactoryBean readEntityManagerFactory(
          EntityManagerFactoryBuilder builder,
          @Qualifier("readDataSource") DataSource readDataSource) {
    return builder
            .dataSource(readDataSource)
            .packages("com.foobar") // Your JPA entity package
            .persistenceUnit("read")
            .properties(Map.of(
                    // Do not try fo fetch Database Metadate without Sharding Key
                    "hibernate.boot.allow_jdbc_metadata_access", "false",
                    // Disable DDLs for Sharded data source
                    "hibernate.hbm2ddl.auto", "none",
                    "hibernate.show_sql", false, // Explicitly disable
                    "hibernate.format_sql", false,
                    "hibernate.dialect", "org.hibernate.dialect.OracleDialect"
            ))
            .build();
  }

  // Read TransactionManager
  @Bean(name = "readTransactionManager")
  public PlatformTransactionManager readTransactionManager(
          @Qualifier("readEntityManagerFactory") EntityManagerFactory readEntityManagerFactory) {
    return new JpaTransactionManager(readEntityManagerFactory);
  }

  @Bean
  ShardingKeyProvider readShardingKeyProvider() {
    return new ShardingKeyProvider() {
      public ShardingKey getShardingKey() throws SQLException {
        String shardingKey = ShardingController.getShardingKeyContext().get();
	    log.info("Shardingkey: " + shardingKey);
        if (shardingKey == null) {
          return null;
        }
        return new OracleShardingKeyBuilderImpl().subkey(shardingKey, OracleType.VARCHAR2).build();
      }
      // We don't have a super sharding/grouping key
      public ShardingKey getSuperShardingKey() {
        //String groupKey = ShardingController.getShardingKeyContext().get();
	    //log.info("groupKey: " + groupKey);
        //ShardingKey retval = new OracleShardingKeyBuilderImpl()
        //        .subkey(groupKey, OracleType.VARCHAR2)
        //        .build();
        return null;
      }
    };
  }

}
