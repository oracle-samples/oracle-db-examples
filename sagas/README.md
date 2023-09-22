# SagaBenchmark

Repository for saga benchmark application.  This application mimics a real application and drives a saga workload for various participants.

## Getting started

In order to drive the application, you will need to install Artillery (global installation is recommended).

```
npm install -g artillery@latest
```

Then install all of the driver dependencies via npm

```
npm install
```

Set up the connection properties

Copy the template file `application.properties.example` in src/main/resources in the parent module to `application.properties`. Modify the property file to fit your environment. This only needs to be done once. A wallet and tnsnames.ora is required, see https://docs.oracle.com/middleware/1213/wls/JDBCA/oraclewallet.htm#JDBCA598 on how to create a wallet.

Run `mvn clean install` which will copy the properties file as well as build and package each of the applications.

From the root directory, create a `sql` directory, i.e., `mkdir sql` then run `mvn exec:java -pl sqlgenerator`. This will run the sql generator program that will generate all of the necessary sql scripts into the `sql` subdirectory. Modify `setupPDBS.sql` to match your CDB details, specifically, change `<seed_database>` on the `create pluggable database` lines to the value of your seed database.

Copy `initdb.sh.example` to `initdb.sh` and mark it as executable, i.e. `chmod a+x ./initdb.sh`

Modify `initdb.sh` with the correct credentials and connection strings for the environment. To (re)initialize the database, run `./initdb.sh`

**Note**: `sqlplus` is required and must be in your path.

## Usage

From the base directory, run `mvn clean install` to build everything.

**Optional** Copy setenv.sh into the bin folder of the Tomcat directory. This will add some network and JMS tuning as well as add some additional logging.

The application is split into 4 components. The Travel Agency is a WAR that needs to be deployed into a Tomcat 10 container. The Airline and Car applications are standalone Java apps. To start the Airline, run `mvn exec:java` from the airline directory. Similary, to start Car, run `mvn exec:java` from the car directory.

To run the driver, run `npm start` (you may need to run `npm install` first to install the JavaScript dependencies).

This will produce a `report.html` in the same directory which shows the results of the run.

## Benchmark Parameters

### application.properties

* maxStatusWait

The status endpoint will check to see when the original request was sent to create the saga. On each invocation of the status endpoint, it will check the delta between the creation time and now. If that exceeds `maxStatusWait`, the endpoint will return a 504. This parameter is in milliseconds.

* cacheSize

The initial cache size for each of the participants. This cache is used to maintain saga state information during the run such as compensation information.

* queuePartitions

The number of queues to use at each of participants (plus internal infrastructure).

* numOfFlightsToCreate

This property indicates how many flights should be added to the Flights table. This information will be used to create a payload for booking an airline.

### driver.yaml

* statusWait

How long the driver will wait (in seconds) between status checks to see if the saga has completed.

## Misc

### Sample Payload
```
{
  "flight": {
    "action": "Booking",
    "passengers": [
      {
        "firstName": "Jack",
        "lastName": "Frost",
        "birthdate": "1992-02-10",
        "gender": "F",
        "email": "sbt@yahoo.com",
        "phonePrimary": "949-767-9979",
        "flightId": "1",
        "seatType": "ECONOMY_SEATS",
        "seatNumber": "23A"
      },
      {
        "firstName": "Sam",
        "lastName": "Frost",
        "birthdate": "1990-08-30",
        "gender": "M",
        "email": "snua@yahoo.com",
        "phonePrimary": "949-767-9967",
        "flightId": "1",
        "seatType": "ECONOMY_SEATS",
        "seatNumber": "23B"
      }
    ]
  },
  "car": {
    "action": "Booking",
    "customer": "John Case",
    "phone": "898-908-9080",
    "driversLicense": "B189391",
    "birthdate": "1976-03-04",
    "startDate": "2022-04-05",
    "endDate": "2022-04-15",
    "carType": "Van"
  }
}
```
