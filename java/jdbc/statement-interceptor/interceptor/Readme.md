# SQL Interceptor
![oveview](/assets/img/overview.png)

This project demonstrates how the _TraceEventListener_ feature can be used for security
enhancement of user applications. The idea here is being able to intercept any SQL statement
issued by an Oracle JDBC client application and, based on given rules, to allow or not this statement
to proceed and reach the remote server. 

The feature is delivered as part of a _TraceEventListenerProvider_. This provider
puts in place a listener who listens to connection round-trips to the remote server.
Any statement are then analysed by a set of "statement rules" that "authorize" or not 
the request to go on. 

A statement rule (_StatementRule_) is a class that receives a SQL statement as input
and take action if that statement represents a risk.

This advantage of such interceptor is that it can be plugged transparently to 
any existing application without any code change, it does not require any extra layer of software (like 
by setting up a firewall o proxy), it may help to prevent some DOS by just forbidding
statements to reach the RDBMS. 

## Running the application

A demonstration usage is provided by this other project
https://orahub.oci.oraclecorp.com/ora-jdbc-dev/jdbc-statement-interceptor-webdemo

As a quick test program you can choose to use the small main application of this project.

In order to run it the following System properties must be set:

- com.oracle.jdbc.samples.url: JDBC url of the remote server
- com.oracle.jdbc.samples.user: username of the connection
- com.oracle.jdbc.samples.password: user password.

### Running from IntelliJ project

Select the Main.java in source tree and activate 'run Main.main()'

### Running from Gradle

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

#### Example

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
