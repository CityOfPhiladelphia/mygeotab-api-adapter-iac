# My Geotab API Adapter

## Components

All components are deployed directly on the server, none are containerized

* MyGeotabApiAdapter
* Alloy - Sends metrics and log files to Grafana
* Auto restarter cron job

## Design Choices

### Server Infrastructure

The MyGeotabApiAdapter application does not support any type of clustering or high availability, so it is deployed as a singleton. There were no officially supported docker containers for it either, so it is simply installed on the server.

#### Server provisioning

Upon launching an EC2 from the autoscaling group (or directly from the launch template), a short userdata script runs which downloads this Git repository and then executes the [servers/build.sh](server/build.sh) script.

#### Auto restarter cron job

On one occasion, this application crashed with vague error messages, but importantly did not report that to `systemctl`, which still reported it was running. Since `systemctl` can not reliably determine if the application is running or not, a custom script was written that checks every minute when the most recent database entry was made. Since this application should continuously write to the database, any delay of more than 5 minutes will automatically restart the service (only if it claims it is running).

### AWS Infrastructure

AWS infrastructure is deployed with Terraform.

Despite the lack of clustering support, an autoscaling group is still used to deploy the server because it simplifies the process and maintenance. This autoscaling group should always have its capacity set to 1 except during maintenance.

#### Architecture Diagram

![architecture diagram](docs/arch_diagram.svg)

### Terraform infrastructure

Although there is only one environment (prod), the terraform infrastructure was designed to enable multiple environments if the need arises. There is a primary module in [terraform/modules/app](terraform/modules/app) which essentially includes the entire core infrastructure. The environments in the [terraform/env](terraform/env) folder each use this module with variables relevant to that environment. There is also an inline project in [terraform/common](terraform/common) which creates the common KMS. Any parameters that may be needed by the server are also deployed as SSM (systems manager) parameters.

### CI/CD infrastructure

Use of the CI/CD enables automatic deployment and testing of the infrastructure.

#### CI - All branches and pull requests

* tflint - Checks invalid values, prohibits poor coding practices
* terraform fmt - Ensures consistent formatting
* terraform plan - Investigate what Terraform will do perform merging to main
* shellcheck - Lints [build.sh](server/build.sh)

#### CD - Main branch only

* terraform apply - Deploys Terraform infrastructure
* [indirect] On launch, a server downloads the code from the main branch

## Development

When developing new features, it is best to test the full functionality before merging to `main`. This is because the CI integration, while thorough for verifying the Terraform code itself, does not verify that the actual code will work as intended.

Since we only budgeted a single environment, the prod environment, any development would either require downtime, or would require a dev environment to be spun up temporarily. Please work with Ryan Weast.

### Getting credentials locally

Check out the credentials that are pulled from Keeper in the [.github/workflows](.github/workflows) files. Set those up locally.

### Developing AWS / Terraform code

Just use `terraform apply` locally from your development machine.

### Developing server configuration

To test server configuration (the server/ folder), push your code to a non-main branch and update the `build_branch` parameter in terraform (in terraform/env/ folder) to that branch name. Then, use Terraform apply to update the launch template to pull from that new build branch, then replace the server. Since we only have the `prod` environment, this would cause outage. Make sure to change the `build_branch` back to main before merging the changes to main.

## Maintenance

See [docs/maintenance.md](docs/maintenance.md)

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
  PASSWORD 'XXXXX';

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
