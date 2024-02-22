/*
 * Copyright (c) 2023 Oracle and/or its affiliates.
 *
 * The Universal Permissive License (UPL), Version 1.0
 *
 * Subject to the condition set forth below, permission is hereby granted to any
 * person obtaining a copy of this software, associated documentation and/or data
 * (collectively the "Software"), free of charge and under any and all copyright
 * rights in the Software, and any and all patent rights owned or freely
 * licensable by each licensor hereunder covering either (i) the unmodified
 * Software as contributed to or provided by such licensor, or (ii) the Larger
 * Works (as defined below), to deal in both
 *
 * (a) the Software, and
 * (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
 * one is included with the Software (each a "Larger Work" to which the Software
 * is contributed by such licensors),
 *
 * without restriction, including without limitation the rights to copy, create
 * derivative works of, display, perform, and distribute the Software and make,
 * use, sell, offer for sale, import, export, have made, and have sold the
 * Software and the Larger Work(s), and to sublicense the foregoing rights on
 * either these or other terms.
 *
 * This license is subject to the following condition:
 * The above copyright notice and either this complete permission notice or at
 * a minimum a reference to the UPL must be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package com.oracle.jdbc.samples.springsharding.configuration;

import com.oracle.jdbc.samples.springsharding.model.Note;
import com.oracle.jdbc.samples.springsharding.model.User;
import jakarta.servlet.http.HttpServletRequest;
import oracle.jdbc.OracleType;
import oracle.jdbc.pool.OracleShardingKeyBuilderImpl;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.jdbc.datasource.ShardingKeyProvider;
import org.springframework.jdbc.datasource.ShardingKeyDataSourceAdapter;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.servlet.HandlerMapping;

import javax.sql.DataSource;
import java.sql.SQLException;
import java.sql.ShardingKey;
import java.util.Map;
import java.util.Objects;

/**
 * A Direct Shard Datasource is used to establish connections to the shard directors, it should be used in cases where
 * we only need to connect to a single shard which is identified by providing a sharding key.
 */
@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
        // This tells spring to use this configuration for all the repositories under the below package
        basePackages = "com.oracle.jdbc.samples.springsharding.dataaccess.directshard",
        entityManagerFactoryRef = "directShardEntityManagerFactory",
        transactionManagerRef = "directShardTransactionManager"
)
public class DirectShardDataSourceConfig {
    @Value("${oracle.database.directshard.url}")
    private String url;
    @Value("${oracle.database.directshard.username}")
    private String user;
    @Value("${oracle.database.directshard.password}")
    private String password;

    private final HttpServletRequest httpRequest;

    public DirectShardDataSourceConfig(HttpServletRequest httpRequest) {
        this.httpRequest = httpRequest;
    }

    /**
     * Bean definition of the ShardingKeyProvider. The sharding key is extracted from the http request path variables.
     *
     * @return A ShardingKeyProvider that gets the sharding key from the http request path variables.
     */
    @Bean
    ShardingKeyProvider shardingKeyProvider() {
        return new ShardingKeyProvider() {
            public ShardingKey getShardingKey() throws SQLException {
                // On start up hibernates opens a connection to the database to do some initial setup, not setting
                // a sharding key causes UCP to throw an exception, to avoid this problem we initialize the sharding key
                // with -1
                Long shardingKey = -1L;

                // Get the sharding key (userId) from the request path variables
                if (RequestContextHolder.getRequestAttributes() != null) {
                    Object httpAttributes = httpRequest.getAttribute(HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE);
                    Map<String, String> pathVariables = (Map<String, String>) httpAttributes;

                    if (pathVariables.containsKey("userId")) {
                        shardingKey = Long.parseLong(pathVariables.get("userId"));
                    }
                }

                return new OracleShardingKeyBuilderImpl().subkey(shardingKey, OracleType.NUMBER).build();
            }
            // We don't have a super sharding key
            public ShardingKey getSuperShardingKey() {
                return null;
            }
        };
    }

    /**
     * Bean definition of the Direct Shard connection pool.
     * The created Datasource is an instance of the ShardingKeyDataSourceAdapter, it allows setting direct
     * connections to specific shards identified by a shardingKey.
     * The shardingKey, used to identify the shards, is extracted using the {@link #shardingKeyProvider}.
     *
     * @return A DataSource representing the Direct Shard connection pool.
     */
    @Bean
    public DataSource directShardDataSource(ShardingKeyProvider shardingKeyProvider) throws SQLException {
        // This is a UCP DataSource
        PoolDataSource dataSource = PoolDataSourceFactory.getPoolDataSource();

        dataSource.setURL(url);
        dataSource.setUser(user);
        dataSource.setPassword(password);
        dataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        // We are setting the initial pool size to 0 because if we create a connection without setting a sharding key
        // they would all point to a single shard, because we initialize the sharding key with -1.
        dataSource.setInitialPoolSize(0);
        dataSource.setMinPoolSize(0);
        dataSource.setMaxPoolSize(20);

        return new ShardingKeyDataSourceAdapter(dataSource, shardingKeyProvider);
    }

    /**
     * EntityManagerFactory bean definition that is associated with the Direct Shard connection pool.
     *
     * @return An EntityManagerFactory instance associated with the Direct Shard connection pool
     */
    @Bean
    public LocalContainerEntityManagerFactoryBean directShardEntityManagerFactory(
            @Qualifier("directShardDataSource") DataSource dataSource,
            EntityManagerFactoryBuilder builder) {
        return builder
                .dataSource(dataSource)
                .packages(User.class, Note.class)
                .build();
    }

    /**
     * TransactionManager bean definition that is associated with the Direct Shard connection pool
     *
     * @return A PlatformTransactionManager instance associated with the Direct Shard connection pool
     */
    @Bean
    public PlatformTransactionManager directShardTransactionManager(
            @Qualifier("directShardEntityManagerFactory") LocalContainerEntityManagerFactoryBean entityManagerFactory) {
        return new JpaTransactionManager(Objects.requireNonNull(entityManagerFactory.getObject()));
    }
}
