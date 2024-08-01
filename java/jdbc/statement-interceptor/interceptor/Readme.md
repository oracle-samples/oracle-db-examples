# SQL Interceptor
![oveview](assets/img/overview.png)

This project demonstrates how the new 23ai Oracle JDBC feature [TraceEventListener](https://docs.oracle.com/en/database/oracle/oracle-database/23/jajdb/oracle/jdbc/TraceEventListener.html) can be used for security enhancement of Java applications.
The [TraceEventListener](https://docs.oracle.com/en/database/oracle/oracle-database/23/jajdb/oracle/jdbc/TraceEventListener.html) is a callback that can be registered for every roundtrip made to the Database. This particular implementation can intercept any SQL statement issued by an Oracle JDBC client application and, based on given rules, allow the statement to proceed and reach the remote server.

This TraceEventListenerProvider registers a listener that analyzes all round-trips made to the remote server.
All statements are then analysed by a set of "statement rules" that "authorize" or not the request to go on.

A statement rule _StatementRule_ is a class that processes a SQL statement as input and executes an action if that statement matches a rule.
Rules can be used to identify security risks, such as a SQL injection attacks.

The advantage of such interceptor is that it can be plugged-in transparently to any existing application without any code change. 
It does not require any extra layer of software (like etting up a firewall or proxy), it may help to prevent some DOS by just forbidding statements to reach the Oracle Database server.

## Running the application

Be sure that you use gradle 8.5 or above.

A demonstration usage is provided by this other project

[Interceptor Demo App](https://github.com/oracle-samples/oracle-db-examples/tree/7aaa7ae05d36a7127cd5bd4bb84e66301f45908c/java/jdbc/statement-interceptor/demo-app)

As a quick test program you can choose to use the small main application of this project.

In order to run it the following System properties must be set:

- com.oracle.jdbc.samples.url: JDBC url of the remote server
- com.oracle.jdbc.samples.user: username of the connection
- com.oracle.jdbc.samples.password: user password.

### Running from IntelliJ project

Select the Main.java in test source tree and activate 'run Main.main()'

### Running from Gradle

Be sure that you use gradle 8.5 or above.

provide the following property to the gradle build (command lien or using gradle.properties file)

```bash
./gradlew run
```
## maven dependency

This interceptor is published on jdbc-dev-local maven repository as

```xml
<metadata modelVersion="1.1.0">
    <groupId>com.oracle.database.jdbc</groupId>
    <artifactId>JDBCInterceptor</artifactId>
</metadata>
```


## Concepts

### Rule

A statement rule is a class that implements the _com.oracle.jdbc.samples.interceptor.StatementRule_ interface, it takes a parameter as input.
This project comes with three sample implementations.
#### RegExpStatementRule
This implementation of _com.oracle.jdbc.samples.interceptor.StatementRule_ matches
the SQL statement against a regular expression. See resource/rules.json for example.

#### AttackStatementRule
This implementation of _com.oracle.jdbc.samples.interceptor.StatementRule_ matches
the SQL statement against wellknown SQL attack. This implementation is empty as we speak 
and only serve demonstration purpose.

#### TokenStatementRule
This implementation of _com.oracle.jdbc.samples.interceptor.StatementRule_ matches
the SQL statement against a given string. See resource/rules.json for example.
We can see this rule as a simplified version of RegExpStatementRule

### Actions

Action taken when a rule matches a SQL statement. Possible actions are:

- LOG: a log message to logger named SQLStatementInterceptor.ACTION_LOGGER_NAME. 
- CONSOLE: a log message is sent to system console.
- RAISE: raise a _SecurityException_.

More than one actions can be defined (ex ['LOG','RAISE']). They are all executed. 'RAISE' must be the last one as it break the code flow (no other action could be executed).

### Provider

`com.oracle.jdbc.samples.interceptor.SQLStatementInterceptorProvider` responsible for gathering rules, configuration and instantiates the listener

### Listener

`com.oracle.jdbc.samples.interceptor.SQLStatementInterceptor` is a trace event listener responsible for analyzing SQL statements.  
When a SQL statement is intercepted, the listener will loop through all defined rules and check if the SQL statement matches the rule. If a match is found (a risk is detected), the actions defined for that given rules are triggered.

### Configuration

The configuration of rules and actions as a JSON file, the latter should contain an array of simple object with the following attributes:

- "className": Fully qualified class name of the rule type.
- "parameter": Parameter of that rule. (Optional)
- "actions": List of action to execute when this rule matches.

#### Interceptor configuration example

```json
[
  {
    "className": "com.oracle.jdbc.samples.interceptor.rules.RegExpStatementRule",
    "parameter": "SELECT 1 *",
    "actions": ["LOG"]
  },
  {
    "className": "com.oracle.jdbc.samples.interceptor.rules.TokenStatementRule",
    "parameter": "DUAL",
    "actions": ["LOG","RAISE"]
  }
]
```
