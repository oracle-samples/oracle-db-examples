/*
 * Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.oracle.adbaoverjdbc.test;

import java.time.Duration;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.function.Function;

import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.DataSourceFactory;

import static com.oracle.adbaoverjdbc.test.TestConfig.Configurable.*;

/**
 * This class encapsulates configurable values used by test classes. Each 
 * configurable value is defined as a type of {@link Configurable}.
 * <br>
 * All configurable values are read by looking up their identifier in the JVM's 
 * system properties. Identifiers are formed as:
 * <br> 
 * <em>com.oracle.adbaoverjdbc.test.TestConfig</em>.[<em>Name-of-Configurable</em>]
 * <br> 
 * For example, this -D command line option would configure the database user:
 * <br>
 * <code>
 * java -Dcom.oracle.adbaoverjdbc.test.TestConfig.USER=SCOTT ...
 * </code>
 * <br>
 * For convenience, configurable values can be identified by their short name,
 * without the <em>com.oracle.adbaoverjdbc.test.TestConfig</em> prefix. For
 * example, this -D command line option would also configure the database user:
 * <br>
 * <code>
 * java -DUSER=SCOTT ...
 * </code>
 * <br>
 * While convenient, potential collisions can arise if some other component 
 * reads the "USER" system property. For this reason, the more unique long
 * form would be a safer choice.
 */
class TestConfig {
  
  private TestConfig() { /* Singleton */ }
  
  /** A prefix for all identifiers defined in this class. */
  private static final String ID_PREFIX = 
    "com.oracle.adbaoverjdbc.test.TestConfig.";
  
  /**
   * Defines types of configuration sources. A configuration source maps 
   * identifiers to configurable values.
   * <br><br>
   * This enum is designed for other types of configuration sources
   * to be added in the future. The {@link CONFIG_SOURCE} field of the 
   * TestConfig class can be set to any enum defined here using the system 
   * property:
   * <em>com.oracle.adbaoverjdbc.TestConfig.CONFIG_SOURCE</em>
   * <br>
   * For example, one might define a new ConfigSource named FILE which reads
   * configurable values from a file. By setting 
   * <code>com.oracle.adbaoverjdbc.test.TestConfig.CONFIG_SOURCE=FILE</code> 
   * , the TestConfig would provide configurable values using 
   * ConfigSource.FILE, instead of the default ConfigSource.SYSTEM_PROPERTIES.
   */
  private enum ConfigSource {
    
    /** Reads configurable values from system properties */
    SYSTEM_PROPERTIES(System::getProperty);
    
    private final Function<String, String> readFn;
    
    private ConfigSource(Function<String, String> readFn) {
      this.readFn = readFn;
    }
    
    /**
     * Returns a configurable value defined in this source. 
     * @param config The type of a configurable value.
     * @return The defined value, or a default value.
     * @throws NoSuchElementException If no value is defined by the 
     *   configuration source, and no default value exists. 
     */
    String get(Configurable config) {
      return Optional.ofNullable(readFn.apply(config.id))
               .or(() -> Optional.ofNullable(readFn.apply(config.toString())))
               .or(config::getDefaultValue)
               .orElseThrow(() -> newUndefinedError(config));
    }

    /**
     * Instantiates and returns a NoSuchElementException which describes a 
     * an undefined configurable value.
     * @param config The type of a configurable value.
     * @return A newly instantiated NoSuchElementException.
     */
    private NoSuchElementException newUndefinedError(
      Configurable config) {
      return new NoSuchElementException(
        "Configuration source " + this 
        + " does not define a value for " + config.id);
    }
  }
  
  /**
   * Defines types of configurable values. The TestConfig class javadoc 
   * provides a full description of each value. 
   */
  enum Configurable {
    
    /**
     * A JDBC style (ie: jdbc:vendor:...) database URL which test classes 
     * establish connections to. A value must be defined when tests are run 
     * (there is no default URL).
     */
    URL, 
    
    /**
     * The user name which test classes provide for database authentication. 
     * A value must be defined when tests are run (there is no default USER).
     */
    USER, 
    
    /**
     * The password which test classes provide for database authentication. 
     * A value must be defined when tests are run (there is no default 
     * PASSWORD). 
     */
    PASSWORD, 
    
    /**
     * A time limit which test classes impose on submitted operations. The 
     * value is expressed as milliseconds. The default value is 15,000 
     * milliseconds.
     */
    TIMEOUT("15000"),
    
    /**
     * The class name which test classes provide when calling
     * {@link jdk.incubator.sql2.DataSourceFactory#newFactory(String)}. The 
     * default value is com.oracle.adbaoverjdbc.DataSourceFactory
     */
    DATASOURCE_FACTORY(
      com.oracle.adbaoverjdbc.DataSourceFactory.class.getName())
    
    ;

    /** The identifier used to define a value for this configurable */
    private final String id;
    
    /** The default value for this configurable, which may be null */
    private final String defaultValue;

    /** Constructs a new Configurable with no default value */
    private Configurable() {
      this(null);
    }

    /** 
     * Constructs a new Configurable with a default value 
     * @param defaultValue A default value
     */
    private Configurable(String defaultValue) {
      this.defaultValue = defaultValue;
      this.id = ID_PREFIX + this.toString();
    }
    
    /**
     * @return An Optional with the default value, which may be an empty 
     *   Optional.
     */
    private Optional<String> getDefaultValue() { 
      return Optional.ofNullable(defaultValue); 
    }
  }

  /**
   * The source of configurable values.
   */
  private static final ConfigSource CONFIG_SOURCE = ConfigSource.valueOf(
     System.getProperty(ID_PREFIX + "CONFIG_SOURCE", 
                        ConfigSource.SYSTEM_PROPERTIES.name()));
  
  /**
   * @return A DatasourceFactory name read from the test configuration source.
   */
  static String getDataSourceFactoryName() { 
    return CONFIG_SOURCE.get(DATASOURCE_FACTORY); 
  }

  /**
   * @return A database URL read from the test configuration source.
   */
  static String getUrl() { 
    return CONFIG_SOURCE.get(URL); 
  }

  /**
   * @return A database user name read from the test configuration source.
   */
  static String getUser() { 
    return CONFIG_SOURCE.get(USER); 
  }

  /**
   * @return A database password read from the test configuration source.
   */
  static String getPassword() { 
    return CONFIG_SOURCE.get(PASSWORD); 
  }
  
  /**
   * @return An operation timeout read from the test configuration source.
   */
  static Duration getTimeout() {
    return Duration.ofMillis(Long.valueOf(CONFIG_SOURCE.get(TIMEOUT)));
  }
  
  /**
   * @return A DataSource configured with the URL, User, and Password read
   *   from the the test configuration source.
   */
  static DataSource getDataSource() {
    return DataSourceFactory.newFactory(getDataSourceFactoryName())
             .builder()
             .url(getUrl())
             .username(getUser())
             .password(getPassword())
             .build();
  }
}
