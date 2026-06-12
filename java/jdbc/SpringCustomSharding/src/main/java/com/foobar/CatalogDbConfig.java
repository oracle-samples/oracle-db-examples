/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar;

import com.foobar.appschema.repo.CatalogCustomerRepository;
import com.foobar.foo.repo.CatalogFooRepository;
import jakarta.persistence.EntityManagerFactory;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.*;
import org.springframework.core.env.Environment;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;
import java.sql.SQLException;
import java.time.Duration;
import java.util.Map;
import java.util.Properties;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.foobar", // Same package
        entityManagerFactoryRef = "catalogEntityManagerFactory",
        transactionManagerRef = "catalogTransactionManager",
        includeFilters = {
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = CatalogCustomerRepository.class),
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = CatalogFooRepository.class),
                @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = CatalogFooRepository.class)
        }
)
public class CatalogDbConfig {

  @Autowired
  private Environment environment;

  @Bean
  @ConfigurationProperties("catalog.datasource")
  public DataSourceProperties catalogDataSourceProperties() {
    return new DataSourceProperties();
  }

  @Bean(name = "catalogDataSource")
  @Primary
  public DataSource dataSource() throws SQLException {
    PoolDataSource dataSource = catalogDataSourceProperties()
            .initializeDataSourceBuilder()
            .type(PoolDataSourceImpl.class)
            .build();
    dataSource.setConnectionProperties(new Properties());
    dataSource.setDataSourceName("catalogDataSource");
    dataSource.setConnectionPoolName("CatalogPool");
    dataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
    dataSource.setMinPoolSize(0);
    dataSource.setInitialPoolSize(0);
    dataSource.setMaxPoolSize(20);
    dataSource.setMaxConnectionsPerShard(5);
    dataSource.setConnectionWaitDuration(Duration.ofSeconds(30));
    dataSource.setValidateConnectionOnBorrow(true);
    return dataSource;
  }

  // catalog EntityManagerFactory
  @Bean(name = "catalogEntityManagerFactory")
  @Primary
  public LocalContainerEntityManagerFactoryBean catalogEntityManagerFactory(
          EntityManagerFactoryBuilder builder,
          @Qualifier("catalogDataSource") DataSource catalogDataSource) {
    return builder
            .dataSource(catalogDataSource)
            .packages("com.foobar") // Your JPA entity package
            .persistenceUnit("catalog")
            .properties(Map.of(
                    "hibernate.boot.allow_jdbc_metadata_access", "false",
                    "hibernate.hbm2ddl.auto", "none",
                    "hibernate.show_sql", false, // Explicitly disable
                    "hibernate.format_sql", false,
                    "hibernate.dialect", "org.hibernate.dialect.OracleDialect"
// Enable DDLs for write data source
            ))
            .build();
  }

  // catalog TransactionManager
  @Bean(name = "catalogTransactionManager")
  @Primary
  public PlatformTransactionManager catalogTransactionManager(
          @Qualifier("catalogEntityManagerFactory") EntityManagerFactory catalogEntityManagerFactory) {
    return new JpaTransactionManager(catalogEntityManagerFactory);
  }
}
