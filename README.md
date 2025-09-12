# My Geotab API Adapter

## Components

### Uncontainerized

* Alloy - Meta monitoring tool. Installed on the base ec2 for maximum metric collection information

## MyGeotab API Adapter Notes

This application has been very strange to set up. It does not support many modern features such as clustering or scaling. The database setup involves manually running a series of 10 or so scripts.

### Clearing up space

The tool does not seem to have a feature that auto deletes old partitions.

```sql
drop table public."EntityMetadata2_YYYYMM" CASCADE;
drop table public."LogRecords2_YYYYMM" CASCADE;
```

Example YYYYMM = 202503

### Errors

* `ERROR|Hosting failed to start System.Exception: The 'AdapterMachineName' of 'XXX' is different than that of 'XXXX' logged in the adapter database for the 'DatabaseMaintenanceService2' AdapterService`
  * Essentially, this tool is trying to "help" you by not accidentally having multiple different servers use the same database, since it is not a clustered application. However, if you turn off the old one and start a new one, it still isn't happy about this. To solve  this, I noticed that it was only using the part of the server's hostname up to the first dot, so I simply set the hostname to "mygeotab-api-adapter.whatever" so it thinks it is always the same server. If we adjust this in the future, use this sql command: `UPDATE public."OServiceTracking2" set "AdapterMachineName"='XXX';`
* Setting up database for the first time
  * Ideally this won't have to happen again because it was tedious. Also, the instructions didn't directly work on RDS
    * Step 2 must be altered

```sql
CREATE ROLE geotabadapter_client WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  PASSWORD 'Q!AC=_2zi9;9MR?';

# Comment out OWNER and TABLESPACE

CREATE DATABASE geotabadapterdb WITH
--  OWNER = geotabadapter_client
  ENCODING = 'UTF8'
  LC_COLLATE = 'en_US.UTF-8'
  LC_CTYPE = 'en_US.UTF-8'
--  TABLESPACE = pg_default
  CONNECTION LIMIT = -1
  IS_TEMPLATE = FALSE;

ALTER DATABASE geotabadapterdb OWNER TO geotabadapter_client

```

    * These extensions must be installed. Do this by logging into the new DB not as the service user, but as the postgres admin user `CREATE EXTENSION IF NOT EXISTS pgstattuple; CREATE EXTENSION IF NOT EXISTS pg_stat_statements;`
