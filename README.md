#CF SAP HANA Broker

CF SAP HANA Broker exposes SAP HANA database as a Cloud Foundry service.  This broker supports the v2 services API between cloud controllers and service brokers. 

The broker does not include a SAP HANA DB server. Instead, it is meant to be deployed alongside a SAP HANA server, which it manages.  These are the SAP HANA management tasks that the broker performs.

* Provisioning of database schemas (create)
* Creation of credentials (bind)
* Removal of credentials (unbind)
* Unprovisioning of database schemas (delete)

## Warning
####The new services API is still in progress and may change at any time. 


## Running broker
#### $ rake server [-p <broker port>]

## Running Tests

The CF SAP HANA Broker integration specs will exercise the catalog fetch, create, bind, unbind, and delete functions against its locally installed database.

1. Run SAP HANA server.
2. Pre-configure unixODBC DSN:
	*  cat ~/.odbc.ini
		[hanacloud]
		Description=<HDB instance>
		Driver=HDBODBC
		ServerNode=<HDB instance hostname>:<HDB instance port>
		User:<HDB system account name>
		Password:<Password of HDB system account name>
	*  cat ~/.odbcinst.ini
		[ODBC]
		TraceFile       = 
		Trace           = No
		ForceTrace      = No
		Pooling         = No

		[HDBODBC]
		Description = "SmartCloud"
		Driver=<path to the HBD ODBC driver>/libodbcHDB.so
3. Edit  config/database.yml file according with unixODBC DSN

4. Limitations:
  * Specs have only been tested with SAP HANA 1.0 SP6
  * Suggested to prevent passwords expiration and disable "password change on first login" features by executing following SQL statement and DB server restart:
		
	ALTER SYSTEM ALTER CONFIGURATION ('indexserver.ini','SYSTEM') set 
	('password policy', 'force_first_password_change') = 'false',
	('password policy', 'maximum_password_lifetime') = '90000'
	WITH RECONFIGURE;

5. Run the following commands

```
$ cd cf-hanadb-broker
$ bundle
$ bundle exec rake spec


