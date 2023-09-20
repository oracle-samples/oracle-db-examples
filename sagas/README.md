# SagaBenchmark

Repository for saga benchmark application.  This application mimics a real application and drives a saga workload for various participants.

## Getting started

*Note*: You will need the saga jar from the saga annotations project.

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

From the root directory, run `mvn exec:java -pl sqlgenerator`. This will run the sql generator program that will generate all of the necessary sql scripts into the `sql` subdirectory.

Copy `initdb.sh.example` to `initdb.sh` and mark it as executable, i.e. `chmod a+x ./initdb.sh`

Modify `initdb.sh` with the correct credentials and connection strings for the environment. To (re)initialize the database, run `./initdb.sh`

**Note**: `sqlplus` is required and must be in your path.

## Usage

From the base directory, run `mvn clean install` to build everything.

**Optional** Copy setenv.sh into the bin folder of the Tomcat directory. This will add some network and JMS tuning as well as add some additional logging.

The application is split into 4 components. The Travel Agency is a WAR that needs to be deployed into a Tomcat 10 container. The Airline and Car applications are standalone Java apps. To start the airline, run `mvn exec:java` from the sagabenchmark/airline directory, where N is the number of the airline instance, e.g., 1 would create a participant called Airline1.

To run the driver, run `npm start` (you may need to run `npm install` first to install the JavaScript dependencies).

This will produce a `report.html` in the same directory which shows the results of the run.

## Benchmark Parameters

### application.properties

* maxStatusWait

The status endpoint will check to see when the original request was sent to create the saga. On each invocation of the status endpoint, it will check the delta between the creation time and now. If that exceeds `maxStatusWait`, the endpoint will return a 504. This parameter is in milliseconds.

* cacheSize

The initial cache size for each of the participants. This cache is used to maintain saga state information during the run such as compensation information.

* participantCount

The number of participants to use in the benchmark. This number includes the travel agency, i.e., a value of 5 would mean 1 travel agency and 4 airlines.

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
### Validation Checks

The following validation checks are being made when we run the benchmark test. However, these validation may not complete properly during the driver.yml run. If that is the case the 
validation can be performed after the test has completed by running the following endpoint commands using a tool such as Postman. 

#### Validating Booked Seat Counts
To validate the number of booked seats is accurate send the following request:
```
GET localhost:8080/travelagency/flight/isTotalBookedSeatsValid
```
This request should send back a response similar to the one described below.

```
{
    "allFlightSeatCountIsValid": true,           [Note: If this value is true then all the flights in the Flight table have an accurate seat count. If false one or more flight has an inaccurate seat count.]
    "seatAvailability": [
        {
            "availableBussinessValid": true,     [Note: If true the available business seat count for the specified flight is correct.]
            "availableEconomyValid": true,       [Note: If true the available economy seat count for the specified flight is correct.]
            "availiableFirstClassValid": true,   [Note: If true the available first class seat count for the specified flight is correct.]
            "businessDiff": 105,                 [Note: Diff calculated by taking the <seatType>_initial value from track_flight_seats table and <seatType>_seats from flights table. If the total and diff value match the seat count is valid.]
            "businessTotal": 105,		  [Note: Seat total is calculated by summing up all the booked and unbooked seats and subtracted the booked seats from the unbooked seats in the track_booked_and_unbooked table.]
            "economyDiff": 107,
            "economyTotal": 107,
            "firstClassDiff": 82,
            "firstClassTotal": 82,
            "flightId": 200
        },
        {
            "availableBussinessValid": true,
            "availableEconomyValid": true,
            "availiableFirstClassValid": true,
            "businessDiff": 100,
            "businessTotal": 100,
            "economyDiff": 86,
            "economyTotal": 86,
            "firstClassDiff": 93,
            "firstClassTotal": 93,
            "flightId": 201
        }
    ]
}
```

#### Validating Persistent Queues
To validate the persistent queues (i.e gv$persistent_queues) send the following request:
```
POST localhost:8080/travelagency/persistentQueue/isPersistentQueueMsgsValid
```
The request should be sent with a payload that looks like the one described below.

**Note**: replace the value 4400 with the "vusers.created" value in the test.json file that get created after running the benchmark test.

```
{"vuserCount":4400}  

```

This request should send back a response similar to the one described below.

```
{
    "allPersistentQueueValid": false,	      [Note: If this value is true then all the persistent queues being checked for the dequeue and enqueue message counts have the expected count value. Otherwise one or more queues have incorrect counts.]
    "persistentQueues": [
        {
            "dequeueMsgsCountValid": false,   [Note: If true the dequeue message count for the specified queueName has the expected message count, otherwise false.]
            "dequeuedMsgs": 516,	       [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 12]
            "enqueueMsgsCountValid": false,   [Note: If true the enqueue message count for the specified queueName has the expected message count, otherwise false.]
            "enqueuedMsgs": 516,              [Note: The enqueue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 12]
            "queueName": "SAGA$_TEST_INOUT"
        },
        {
            "dequeueMsgsCountValid": false,
            "dequeuedMsgs": 172,                     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 4]
            "enqueueMsgsCountValid": false,
            "enqueuedMsgs": 172,                     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 4]
            "queueName": "SAGA$_TACOORDINATOR_IN_Q"
        },
        {
            "dequeueMsgsCountValid": false,
            "dequeuedMsgs": 172,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 4]
            "enqueueMsgsCountValid": false,
            "enqueuedMsgs": 172,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 4]
            "queueName": "SAGA$_TACOORDINATOR_OUT_Q"
        },
        {
            "dequeueMsgsCountValid": false,
            "dequeuedMsgs": 86,			     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 2]
            "enqueueMsgsCountValid": false,
            "enqueuedMsgs": 86,			     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 2]
            "queueName": "SAGA$_TRAVELAGENCY_IN_Q"
        },
        {
            "dequeueMsgsCountValid": false,
            "dequeuedMsgs": 86,			     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 2]
            "enqueueMsgsCountValid": false,
            "enqueuedMsgs": 86,                      [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 2]
            "queueName": "SAGA$_TRAVELAGENCY_OUT_Q"
        },
        {
            "dequeueMsgsCountValid": true,
            "dequeuedMsgs": 150,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 3]
            "enqueueMsgsCountValid": true,
            "enqueuedMsgs": 150,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 3]
            "queueName": "SAGA$_AIRLINE_IN_Q"
        },
        {
            "dequeueMsgsCountValid": true,
            "dequeuedMsgs": 150,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 3]
            "enqueueMsgsCountValid": true,
            "enqueuedMsgs": 150,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 3]
            "queueName": "SAGA$_AIRLINE_OUT_Q"
        },
        {
            "dequeueMsgsCountValid": false,
            "dequeuedMsgs": 108,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 3]
            "enqueueMsgsCountValid": false,
            "enqueuedMsgs": 108,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 3]
            "queueName": "SAGA$_CAR_IN_Q"
        },
        {
            "dequeueMsgsCountValid": false,
            "dequeuedMsgs": 108,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 3]
            "enqueueMsgsCountValid": false,
            "enqueuedMsgs": 108,		     [Note: The dequeue message count in the database. The expected value for this queueName is calculated by taking the vUsersCount * 3]
            "queueName": "SAGA$_CAR_OUT_Q"
        }
    ],
    "vUsersCount": 50
}

```
