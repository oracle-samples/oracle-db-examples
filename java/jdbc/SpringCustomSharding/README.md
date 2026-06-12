
# Sample Spring Boot project for Oracle Sharded Database

The purpose of this project is to demonstrate interaction between a Java Spring Boot application and an Oracle Sharded database using **User Defined Sharding**.
In this scenario, sharded partitioned tables are deterministically split between regions.

This example demonstrates functionality where Application works with several different Database Shards and chooses the right one.
This process is transparent for Java application.

## License

This project is licensed under the Universal Permissive License (UPL), Version 1.0.
See [LICENSE.txt](LICENSE.txt) for the full license text.

### Abbreviations
- OSD Oracle Sharded Database
- GSM Global Service Manager
- UCP Universal Connection Pool

### Topology
In this scenario, the Sharded Database is split into two regions.

Data (Sharded/Partitioned tables) originating from EMEA are stored in the EMEA Database Sharded while data from APAC are stored in the APAC Database Shard.
Moreover, both Database Shards have read-only Dataguard replica in the oposite region, so each region has access to all the data.

Duplicated tables are stored in the CATALOG database and have a full replica on **all** Database shard.

There are 2 database servers and 5 databases in total.

##### Servers(2 application + 2 database)

    | Hostname       | Region | TCP Port                        | Purpose                                |
    | -------------- | ------ | ------------------------------- | ---------------------------------------|
    | app-server     | EMEA   |                                 | Server where Spring Boot app runs      |
    | gsm-emea       | EMEA   | TNS(1521), ONS(6234)            | GSM Director, runs dispatcher Listener |
    | gsm-shard-emea | EMEA   | TNS(1521,1530, 1531), ONS(6200) | DB Server in EMEA region               |
    | gsm-shard-apac | APAC   | TNS(1530, 1531), ONS(6200)      | DB Server in APAC region               |

##### Databases(1 Catalog + 4 Database Shards)

    | Database name | DB Unique Name | Role       | PDB        | TCP PORT | DB Server      | Listener      |
    | ------------- | -------------- | ---------- | ---------- | -------- | -------------- | ------------- |
    | CATALOG       | CATALOG_RW     | PRIMARY    | PCATALOG   | 1521     | gsm-shard-emea | LISTENER      |
    | EMEA          | EMEA_AT_EMEA   | PRIMARY    | PEMEA      | 1530     | gsm-shard-emea | LISTENER_EMEA |
    | EMEA          | EMEA_AT_APAC   | STANDBY    | PEMEA      | 1530     | gsm-shard-apac | LISTENER_EMEA |
    | APAC          | APAC_AT_EMEA   | STANDBY    | PAPAC      | 1531     | gsm-shard-emea | LISTENER_APAC |
    | APAC          | APAC_AT_APAC   | PRIMARY    | PAPAC      | 1531     | gsm-shard-apac | LISTENER_APAC |

NOTE: Databases use the same service names (`ro_service`, `rw_service`),
therefore each database has to use its own listener and must have a dedicated TCP port number.

GSM acts as director, deciding which database to use, depending on Sharding key data.
The application talks to GSM's Listener and then is redirected to the proper Database Shard depending on the operation (RO/RW) and Sharding Key.

           Region: R_EMEA      │ Region: R_APAC              
           Shardspace: S_EMEA  │ Shardspace: S_APAC    
       ────────────────────────┼─────────────────────
                               │                     
              ┌───────────┐    │                     
        ┌────►│ GSM       │    │                     
        │     └───────────┘    │                     
        │     ┌───────────┐    │                     
        ├────►│ CATALOG   │    │                     
        │     └───────────┘    │                     
        │                      │                     
        │                      │                     
        │    ┌──────────────┐  │  ┌──────────────┐     
        │    │┌────────────┐│  │  │┌────────────┐│    
        ├────►│EMEA_AT_EMEA│==DG==►│EMEA_AT_APAC││     
        │    │└────────────┘│  │  │└────────────┘│     
        │    │┌────────────┐│  │  │┌────────────┐│     
        ├────►│APAC_AT_EMEA│◄==DG==│APAC_AT_APAC│◄───┐  
        │    │└────────────┘│  │  │└────────────┘│   │  
        │    │EMEA          │  │  │APAC          │   │  
        │    │DB Server     │  │  │DB Server     │   │ 
        │    └──────────────┘  │  └──────────────┘   │  
        │                      │                     │
        │    ┌──────────────┐  │                     │
        │    │┌────────────┐│  │                     │
        └────┼┤UCP         ┼┼────────────────────────┘
             │└────────────┘│  │
             │ SpringBoot   │  │
             │ App          │  │
             └──────────────┘  │                     

#### Database Services and String Datasources

UCP is configured with 3 datasources,

- For reporting, this one connects directly to PCATALOG database
- For read-only operations (`ro_service`)
- For read-write operations (`rw_service`)

GSM operates two DB services: `ro_service`, `rw_service`

    GDSCTL> status service
    Service "ro_service.orasdb.oradbcloud" has 4 instance(s). Affinity: LOCALPREF
    Instance "orasdb%1", name: "EMEA", db: "emea_at_emea_pemea", region: "r_emea", status: ready.
    Instance "orasdb%11", name: "APAC", db: "apac_at_apac_papac", region: "r_apac", status: ready.
    Instance "orasdb%21", name: "APAC", db: "apac_at_emea_papac", region: "r_emea", status: ready.
    Instance "orasdb%31", name: "EMEA", db: "emea_at_apac_pemea", region: "r_apac", status: ready.
    Service "rw_service.orasdb.oradbcloud" has 2 instance(s). Affinity: ANYWHERE
    Instance "orasdb%1", name: "EMEA", db: "emea_at_emea_pemea", region: "r_emea", status: ready.
    Instance "orasdb%11", name: "APAC", db: "apac_at_apac_papac", region: "r_apac", status: ready.

- **ro_service** - allows reading from all databases, preferably from the local region R_EMEA
- **rw_service** - service is available only on PRIMARY databases

### GSM Build steps

#### Prepare Shard EMEA/APAC

- Install Oracle Restart/HAS 26ai on gsm-shard-emea, gsm-shard-apac
- Install Oracle Database 26ai on gsm-shard-emea, gsm-shard-apac
- Create additional listeners on both shards: LISTENER_EMEA (port: 1530), LISTENER_APAC (port: 1531)
- Create database SID: EMEA, DB_UNIQUE_NAME: EMEA_AT_EMEA on gsm-shard-emea
  - Create PDB: PEMEA in DB EMEA
  - Set parameter local_listener to the shard DB **FQDN** hostname and port 1530
  - Execute script shard_emea.sql on the EMEA CDB
  - Create Active DG replica EMEA_AT_APAC on gsm-shard-apac
  - Make sure FLASHBACK is enabled on **both** sides
- Create database SID: APAC, DB_UNIQUE_NAME: APAC_AT_APAC on gsm-shard-apac
  - Create PDB: PAPAC in DB APAC
  - Set parameter local_listener to the shard DB **FQDN** hostname and port 1531
  - Execute script shard_apac.sql on the APAC CDB
  - Create Active DG replica APAC_AT_EMEA on gsm-shard-emea
  - Make sure FLASHBACK is enabled on **both** sides
- Restart all 4 databases and make sure all 4 PDBs are open

#### Prepare GSM Catalog database

- Create database SID: CATALOG, DB_UNIQUE_NAME: CATALOG_RW on gsm-shard-emea
  - Create PDB: PCATALOG
  - Execute script catalog.sql on the CATALOG CDB
  - Restart the database

#### Install GSM

- Install Oracle GSM on host gsm-emea

### Configure GSM

- Note down **all** connection strings for all CDB/PDB databases. Use Oracle DSN rather than EZConnect. For hostnames, use FQDN.
- Run these files as shell scripts on `gsm-emea` under the `oracle` OS user.
  - catalog.sh - configure shard director, invited subnets, shard spaces, regions, and start GSM
  - shard_emea.sh - configure shards: EMEA_AT_EMEA, EMEA_AT_APAC
  - shard_apac.sh - configure shards: APAC_AT_APAC, APAC_AT_EMEA
  - service.sh - configure services: rw_service (RW), ro_service (RO)

Successfully deployed GSM Shards should look like:

    GDSCTL> config shard
    Name                Shard space         Status    State       Region    Availability
    ----                -----------         ------    -----       ------    ------------
    emea_at_emea_pemea  s_emea              Ok        Deployed    r_emea    ONLINE
    emea_at_apac_pemea  s_emea              Ok        Deployed    r_apac    READ ONLY
    apac_at_apac_papac  s_apac              Ok        Deployed    r_apac    ONLINE
    apac_at_emea_papac  s_apac              Ok        Deployed    r_emea    READ ONLY

#### Deploy Sample DB schema

- Connect to PCATALOG as SYSDBA and use `app_schema1.sql` to create the APP_SCHEMA database user.
- Connect to PCATALOG as APP_SCHEMA and use `app_schema2.sql` to create the duplicated table CUSTOMER and the sharded tables ORDERS/ORDERS_ITEM.

#### Deploy Spring Boot app

It can only run on a machine which has full DNS visibility to all hosts involved.
GSM sends redirect messages to UCP client and these messages contain DNS hostname of database server.

```shell
    ./mvnw vefity
    ./mvnw spring-boot:run -DskipTests
```

See config file `application.properties` it contains definition of three data sources:

- Catalog DataSource
- Read DataSource
- Write DataSource

### Verification and Testing

#### Configure Shards

<details>
<summary>Successfully configured Shards should look like this:</summary>

```text

[oracle@gsm-emea ~]$ gdsctl config shard
Name                Shard space         Status    State       Region    Availability
----                -----------         ------    -----       ------    ------------
apac_at_apac_papac  s_apac              Ok        Deployed    r_apac    ONLINE
apac_at_emea_papac  s_apac              Ok        Deployed    r_emea    READ ONLY
emea_at_apac_pemea  s_emea              Ok        Deployed    r_apac    READ ONLY
emea_at_emea_pemea  s_emea              Ok        Deployed    r_emea    ONLINE
```
</details>

#### Configure GSM Services

<details>
<summary>Successfully configured GSM Services should look like this:</summary>

```text
[oracle@gsm-emea ~]$ gdsctl config service
Name           Network name                  Pool           Started Preferred all
----           ------------                  ----           ------- -------------
ro_service     ro_service.orasdb.oradbcloud  orasdb         Yes     Yes
rw_service     rw_service.orasdb.oradbcloud  orasdb         Yes     Yes

[oracle@gsm-emea ~]$ gdsctl status service
Service "ro_service.orasdb.oradbcloud" has 4 instance(s). Affinity: LOCALPREF
   Instance "orasdb%1", name: "EMEA", db: "emea_at_emea_pemea", region: "r_emea", status: ready.
   Instance "orasdb%11", name: "APAC", db: "apac_at_apac_papac", region: "r_apac", status: ready.
   Instance "orasdb%21", name: "APAC", db: "apac_at_emea_papac", region: "r_emea", status: ready.
   Instance "orasdb%31", name: "EMEA", db: "emea_at_apac_pemea", region: "r_apac", status: ready.
Service "rw_service.orasdb.oradbcloud" has 2 instance(s). Affinity: ANYWHERE
   Instance "orasdb%1", name: "EMEA", db: "emea_at_emea_pemea", region: "r_emea", status: ready.
   Instance "orasdb%11", name: "APAC", db: "apac_at_apac_papac", region: "r_apac", status: ready.

[oracle@gsm-emea ~]$ lsnrctl services

LSNRCTL for Linux: Version 23.26.1.0.0 - Production on 12-JUN-2026 13:41:09

Copyright (c) 1991, 2026, Oracle.  All rights reserved.

Connecting to (ADDRESS=(PROTOCOL=tcp)(HOST=)(PORT=1521))
Services Summary...
Service "GDS$CATALOG.oradbcloud" has 1 instance(s).
  Instance "CATALOG", status READY, has 1 handler(s) for this service...
    Handler(s):
      "DEDICATED" established:297 refused:0 state:ready
         REMOTE SERVER
         (ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.local)(PORT=1521))
Service "GDS$COORDINATOR.oradbcloud" has 1 instance(s).
  Instance "CATALOG", status READY, has 1 handler(s) for this service...
    Handler(s):
      "DEDICATED" established:297 refused:0 state:ready
         REMOTE SERVER
         (ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.local)(PORT=1521))
Service "_MONITOR" has 1 instance(s).
  Instance "SHARDDIRECTOR_EMEA", status READY, has 1 handler(s) for this service...
    Handler(s):
      "_MONITOR" established:10 refused:0 current:0 max:5 state:ready
         _MONITOR0
         (ADDRESS=(PROTOCOL=ipc)(KEY=#2308.1)(KEYPATH=/var/tmp/.oracle_80000))
Service "_PINGER" has 1 instance(s).
  Instance "SHARDDIRECTOR_EMEA", status READY, has 1 handler(s) for this service...
    Handler(s):
      "_PINGER" established:0 refused:0 current:0 max:50 state:ready
         _PINGER
         (ADDRESS=(PROTOCOL=ipc)(KEY=#2318.1))
Service "ro_service.orasdb.oradbcloud" has 4 instance(s).
  Instance "orasdb%1", status READY, has 1 handler(s) for this service...
    Handler(s):
      "DEDICATED" established:0 refused:0 state:ready
         REMOTE SERVER
         (ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.local)(PORT=1530))
  Instance "orasdb%11", status READY, has 1 handler(s) for this service...
    Handler(s):
      "DEDICATED" established:0 refused:0 state:ready
         REMOTE SERVER
         (ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-apac.local)(PORT=1531))
  Instance "orasdb%21", status READY, has 1 handler(s) for this service...
    Handler(s):
      "DEDICATED" established:0 refused:0 state:ready
         REMOTE SERVER
         (ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.local)(PORT=1531))
  Instance "orasdb%31", status READY, has 1 handler(s) for this service...
    Handler(s):
      "DEDICATED" established:0 refused:0 state:ready
         REMOTE SERVER
         (ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-apac.local)(PORT=1530))
Service "rw_service.orasdb.oradbcloud" has 2 instance(s).
  Instance "orasdb%1", status READY, has 1 handler(s) for this service...
    Handler(s):
      "DEDICATED" established:0 refused:0 state:ready
         REMOTE SERVER
         (ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.local)(PORT=1530))
  Instance "orasdb%11", status READY, has 1 handler(s) for this service...
    Handler(s):
      "DEDICATED" established:0 refused:0 state:ready
         REMOTE SERVER
         (ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-apac.local)(PORT=1531))
The command completed successfully


```
</details>

#### Testing connectivity

Use this SQL to test Database connection:

```sql92
set line 180
col GLOBAL_NAME for a16
col DB_UNIQUE_NAME for a16
col HOST_NAME for a20
col SERVICE_NAME for a40
col CLIENT_IDENTIFIER for a40
col PDB_NAME for a10

SELECT g.global_name,
       d.db_unique_name,
       d.database_role,
       i.host_name,
       SYS_CONTEXT('USERENV','CON_NAME')     AS pdb_name,
       SYS_CONTEXT('USERENV','SERVICE_NAME') AS service_name,
       SYS_CONTEXT('USERENV','CLIENT_IDENTIFIER') AS client_identifier
FROM   global_name g,
       v$database d,
       v$instance i;

exit
```
#### Prepare file ~/.tnsnames.ora for sqlplus tests

```text
PCATALOG_RW=(DESCRIPTION=(ADDRESS=(HOST=gsm-shard-emea)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=pcatalog)))
SHARDDIRECTOR_EMEA=(DESCRIPTION=(ADDRESS=(HOST=gsm-emea)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=GDS$CATALOG.oradbcloud)))

RW=(DESCRIPTION=(ADDRESS=(HOST=gsm-emea)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=rw_service.orasdb.oradbcloud)))
RO=(DESCRIPTION=(ADDRESS=(HOST=gsm-emea)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=ro_service.orasdb.oradbcloud)(REGION=R_EMEA)))

# Sample Connection string utilizing Sharding Key
SPAIN_W=(DESCRIPTION=(ADDRESS=(HOST=gsm-emea)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=rw_service.orasdb.oradbcloud)(REGION=R_EMEA)(SHARDING_KEY=Spain)))
SPAIN_R=(DESCRIPTION=(ADDRESS=(HOST=gsm-emea)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=ro_service.orasdb.oradbcloud)(REGION=R_EMEA)(SHARDING_KEY=Spain)))

INDIA_W=(DESCRIPTION=(ADDRESS=(HOST=gsm-emea)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=rw_service.orasdb.oradbcloud)(REGION=R_EMEA)(SHARDING_KEY=India)))
INDIA_R=(DESCRIPTION=(ADDRESS=(HOST=gsm-emea)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=ro_service.orasdb.oradbcloud)(REGION=R_EMEA)(SHARDING_KEY=India)))
```

#### Finally demonstrate what SHARDING_KEY does

Country name is used as **Partitioning Key** in ORDERS table, it is also used as **Sharding key** for whole table family.
GSM will pick best database for you depending on whether you want to read or write data and which Table Partition do you want to access.

```
$ sqlplus -S app_schema/@INDIA_R @ses

GLOBAL_NAME	 DB_UNIQUE_NAME   DATABASE_ROLE    HOST_NAME		PDB_NAME   SERVICE_NAME 			    CLIENT_IDENTIFIER
---------------- ---------------- ---------------- -------------------- ---------- ---------------------------------------- ----------------------------------------
PAPAC		 APAC_AT_EMEA	  PHYSICAL STANDBY gsm-shard-emea	PAPAC	   R_EMEA%ro_service.orasdb.oradbcloud

$ sqlplus -S app_schema/@INDIA_W @ses

GLOBAL_NAME	 DB_UNIQUE_NAME   DATABASE_ROLE    HOST_NAME		PDB_NAME   SERVICE_NAME 			    CLIENT_IDENTIFIER
---------------- ---------------- ---------------- -------------------- ---------- ---------------------------------------- ----------------------------------------
PAPAC		 APAC_AT_APAC	  PRIMARY	   gsm-shard-apac	PAPAC	   R_EMEA%rw_service.orasdb.oradbcloud

$ sqlplus -S app_schema/@SPAIN_R @ses

GLOBAL_NAME	 DB_UNIQUE_NAME   DATABASE_ROLE    HOST_NAME		PDB_NAME   SERVICE_NAME 			    CLIENT_IDENTIFIER
---------------- ---------------- ---------------- -------------------- ---------- ---------------------------------------- ----------------------------------------
PEMEA		 EMEA_AT_EMEA	  PRIMARY	   gsm-shard-emea	PEMEA	   R_EMEA%ro_service.orasdb.oradbcloud

$ sqlplus -S app_schema/@SPAIN_W @ses

GLOBAL_NAME	 DB_UNIQUE_NAME   DATABASE_ROLE    HOST_NAME		PDB_NAME   SERVICE_NAME 			    CLIENT_IDENTIFIER
---------------- ---------------- ---------------- -------------------- ---------- ---------------------------------------- ----------------------------------------
PEMEA		 EMEA_AT_EMEA	  PRIMARY	   gsm-shard-emea	PEMEA	   R_EMEA%rw_service.orasdb.oradbcloud
```

#### Start Spring Boot application

Start application, this application runs HTTP server on port 8080.
This exposes several REST endpoints. `/metadata/{country}` endpoint implements double dispatch while picking DB Connection from Connection Pool UCP.

1. Depending on HTTP request (GET/POST) Read or Write datasource is chosen
2. Depending on Sharding Key(Country name) the right Database Shard is chosen by GSM/UCP

#### Start the application

```shell
$ ./mvnw spring-boot:run -DskipTests
```

#### Access the applicartion - /metadata/{country} endpoint using curl

```shell
$ curl -X GET http://localhost:8080/metadata/Spain
Instance{HOST_NAME='gsm-shard-emea', VERSION_FULL='23.26.1.0.0', INSTANCE_NAME='EMEA', OPEN_MODE='READ WRITE', SERVICE_NAME='r_emea%ro_service.orasdb.oradbcloud'}?

$ curl -X GET http://localhost:8080/metadata/India
Instance{HOST_NAME='gsm-shard-emea', VERSION_FULL='23.26.1.0.0', INSTANCE_NAME='APAC', OPEN_MODE='READ ONLY WITH APPLY', SERVICE_NAME='r_emea%ro_service.orasdb.oradbcloud'}?

$ curl -X POST http://localhost:8080/metadata/Spain
Instance{HOST_NAME='gsm-shard-emea', VERSION_FULL='23.26.1.0.0', INSTANCE_NAME='EMEA', OPEN_MODE='READ WRITE', SERVICE_NAME='r_emea%rw_service.orasdb.oradbcloud'}!

$ curl -X POST http://localhost:8080/metadata/India
Instance{HOST_NAME='gsm-shard-apac', VERSION_FULL='23.26.1.0.0', INSTANCE_NAME='APAC', OPEN_MODE='READ WRITE', SERVICE_NAME='r_emea%rw_service.orasdb.oradbcloud'}!
```

This example demonstrates functionality where Application works with several different Database Shards and chooses the right one.
This process is transparent for Java application and can be scalled horizonatlly.

#### Customer REST API examples

Create a customer using the DTO-based JSON API:

```shell
curl -X POST 'http://localhost:8080/customers' \
  -H 'Content-Type: application/json' \
  -d '{
    "custId": "CUST-001",
    "firstName": "Alice",
    "lastName": "Brown",
    "custProfile": "{\"country\":\"Denmark\",\"loyalty\":\"gold\"}"
  }'
```

Read a customer back as JSON:

```shell
curl 'http://localhost:8080/customers/CUST-001'
```

Fetch one random customer:

```shell
curl 'http://localhost:8080/customers/random'
```

#### Order REST API examples

Create an order using the flat DTO contract:

```shell
curl -X POST http://localhost:8080/orders \
  -H 'Content-Type: application/json' \
  -d '{
    "country": "Spain",
    "custId": "CUST-001",
    "orderId": 123456789,
    "orderDate": "2026-06-12T20:00:00",
    "sumTotal": 187.45,
    "status": "PAID",
    "items": [
      {
        "itemId": 1,
        "price": 99.95,
        "status": "NEW"
      },
      {
        "itemId": 2,
        "price": 87.50,
        "status": "DONE"
      }
    ]
  }'
```

Read that order back as JSON:

```shell
curl 'http://localhost:8080/orders/Spain/CUST-001/123456789'
```
