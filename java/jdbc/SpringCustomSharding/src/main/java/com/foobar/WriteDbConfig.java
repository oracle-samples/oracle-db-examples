/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar;

import com.foobar.appschema.repo.WriteCustomerRepository;
import com.foobar.appschema.repo.WriteOrderRepository;
import com.foobar.foo.repo.WriteFooRepository;
import jakarta.persistence.EntityManagerFactory;
import javax.sql.DataSource;
import java.time.Duration;

import oracle.jdbc.OracleType;
import oracle.jdbc.pool.OracleShardingKeyBuilderImpl;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import org.springframework.beans.factory.ObjectProvider;
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
import org.springframework.orm.jpa.JpaVendorAdapter;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.persistenceunit.PersistenceUnitManager;
import org.springframework.orm.jpa.vendor.Database;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.transaction.PlatformTransactionManager;

import oracle.ucp.jdbc.PoolDataSource;

import java.sql.SQLException;
import java.sql.ShardingKey;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.foobar", // Same package
        entityManagerFactoryRef = "writeEntityManagerFactory",
        transactionManagerRef = "writeTransactionManager",
        includeFilters = {
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = WriteFooRepository.class),
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = WriteCustomerRepository.class),
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = WriteOrderRepository.class)
        })
public class WriteDbConfig {    
  private static final Logger log = LoggerFactory.getLogger(WriteDbConfig.class);

  @Autowired
  private Environment environment;

  @Bean
  @ConfigurationProperties("write.datasource")
  public DataSourceProperties writeDataSourceProperties() {
    return new DataSourceProperties();
  }

  @Bean(name = "writeDataSource")
  public DataSource dataSource(ShardingKeyProvider writeShardingKeyProvider) throws SQLException {
    PoolDataSource dataSource = writeDataSourceProperties()
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    dataSource.setConnectionProperties(new Properties());
    dataSource.setDataSourceName("writeDataSource");
    dataSource.setConnectionPoolName("WritePool");
    dataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
    dataSource.setMinPoolSize(0);
    dataSource.setInitialPoolSize(0);
    dataSource.setMaxPoolSize(20);
    dataSource.setMaxConnectionsPerShard(5);
    dataSource.setConnectionWaitDuration(Duration.ofSeconds(30));
    dataSource.setValidateConnectionOnBorrow(true);
    String poolName = dataSource.getConnectionPoolName();
    String ons = dataSource.getONSConfiguration();
    return new ShardingKeyDataSourceAdapter(dataSource, writeShardingKeyProvider);
  }

  // Write EntityManagerFactory
  @Bean(name = "writeEntityManagerFactory")
  public LocalContainerEntityManagerFactoryBean writeEntityManagerFactory(
          EntityManagerFactoryBuilder builder,
          @Qualifier("writeDataSource") DataSource writeDataSource) {
    return builder
            .dataSource(writeDataSource)
            .packages("com.foobar") // Your JPA entity package
            .persistenceUnit("write")
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

  // Write TransactionManager
  @Bean(name = "writeTransactionManager")
  public PlatformTransactionManager writeTransactionManager(
          @Qualifier("writeEntityManagerFactory") EntityManagerFactory writeEntityManagerFactory) {
    return new JpaTransactionManager(writeEntityManagerFactory);
  }

  @Bean
  ShardingKeyProvider writeShardingKeyProvider() {
    return new ShardingKeyProvider() {
      public ShardingKey getShardingKey() throws SQLException {
        String shardingKey = ShardingController.getShardingKeyContext().get();
	    log.info("Shardingkey: " + shardingKey);
        if (shardingKey == null) {
          return null;
        }
        return new OracleShardingKeyBuilderImpl().subkey(shardingKey, OracleType.VARCHAR2).build();
      }

      // We don't have a super sharding key
      public ShardingKey getSuperShardingKey() {
        // String groupKey = ShardingController.getShardingKeyContext().get();
	    // log.info("groupKey: " + groupKey);
        // ShardingKey retval = new OracleShardingKeyBuilderImpl()
        //         .subkey(groupKey, OracleType.VARCHAR2)
        //         .build();
        return null;
      }
    };
  }


}
