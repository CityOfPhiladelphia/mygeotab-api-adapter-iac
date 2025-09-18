# Maintenance

## OS Updates

OS updates can be performed with minimal downtime, potentially only a few seconds.

1. Update AMI in launch template
    1. The automatic AMI updater runs monthly. If you need to force it, go to Github repository -> Actions -> Update AMI -> Run Workflow. This will create a pull request with the latest AMI (if it is newer than the current one)
    1. Check pull request, especially the Terraform plan, for validity
    1. Merge the pull request, then wait for the Terraform apply job to run
    1. *Note* This will not actually update or replace any servers, it just means the next server launched will have the newer AMI.
1. Disable automatic startup
    1. Navigate to AWS web console -> Systems Manager -> Parameter Store
    1. Set "/mygeotab-api-adapter/prod/enable_auto_start" to "no".
1. Launch new server
    1. Navigate to AWS web console -> EC2 -> Autoscaling
    1. Set the desired, minimum, and maximum capacity to 2.
1. SSH onto the new server and make sure things looks good
    1. Check the `/opt` directory
1. Swap which server is active
    1. SSH onto the old server
    1. To minimize downtime, perform the next two steps promptly
    1. \[old server\] Stop the process: `systemctl stop mygeotabadapter`. Wait for the command to finish.
    1. \[new server\] Start the process: `systemctl start mygeotabadapter`
    1. Verify the new server is actually working (check Grafana)
1. Terminate the old server
    1. It's completely acceptable, perhaps recommended to keep the old server up for thirty or so minutes to make sure the new server is working
    1. Navigate to AWS web console -> EC2 -> Autoscaling
    1. Set the desired, minimum, and maximum capacity to 1
1. Re-enable automatic startup
    1. Navigate to AWS web console -> Systems Manager -> Parameter Store
    1. Set "/mygeotab-api-adapter/prod/enable_auto_start" to "yes".

## Application Updates

Application updates require noticeable downtime, but likely less than an hour. This is an unavoidable feature of the application.

The ordering of these steps may seem a bit strange, but they are ordered that way to minimize downtime. The total downtime is essentially: `time it takes to make RDS snapshot before upgrade + time it takes to run any new SQL scripts + time it takes for application to start up`

1. Update `app_version` in Terraform
    1. Create a new branch in the Git repo, maybe like `update-{env}-app-{new_version}`, for example, `update-prod-app-v3-11-0`.
    1. Update `app_version` for the proper environment, in `tf/env/{env}/main.tf`
1. Create the pull request
    1. Check the CI pipeline, especially the `terraform_plan` jobs
1. Merge the pull request, then wait for the CI/CD pipelines to finish
1. Disable automatic startup
    1. Navigate to AWS web console -> Systems Manager -> Parameter Store
    1. Set "/mygeotab-api-adapter/prod/enable_auto_start" to "no".
1. Launch new server
    1. Navigate to AWS web console -> EC2 -> Autoscaling
    1. Set the desired, minimum, and maximum capacity to 2.
1. Quick check on the new server
    1. SSH onto the new server
    1. Make sure that the new version was downloaded properly and things look right
1. Download DB scripts to your local computer
    1. Go to the Github release for the version you are updating to (i.e. <https://github.com/Geotab/mygeotab-api-adapter/releases/tag/{version}>)
    1. Download "PostgreSQL.zip"
1. Get your DB tool of choice connected to the database and ready to run commands
    1. Use any tool of your choice (i.e. DBeaver)
    1. Credentials are in Keeper.
    1. Connect as the service account. **Do not** connect as the admin user (`postgres`)
1. **Downtime starts here**
1. Stop the app on the old server
    1. SSH onto the old server
    1. \[old server\] Stop the process: `systemctl stop mygeotabadapter`. Wait for the command to finish.
1. Create manual RDS snapshot
    1. Since there is no guarantee that the update process goes well, we make a manual RDS snapshot so we can restore it in a disaster scenario.
    1. Navigate to AWS web console -> RDS -> Snapshots
    1. Take a DB snapshot -> DB Instance -> Find correct DB Instance
    1. This takes about 20 minutes
1. ---
1. **WAIT**. Do not proceed until the Snapshot is completely finished.
1. ---
1. Execute the DB update scripts
    1. Pay close attention, because this is a pretty unique update process.
    1. You have to manually execute SQL scripts against the database, sequentially, starting at one higher than the previous minor version. For example, if you are updating from `3.11.0` to `3.13.0`, you must first execute the `3.12.0` script, then the `3.13.0` script. If you are updating only one version, then there is only one script to run
    1. To run the script, basically just copy it into your SQL tool then execute
    1. Make sure there were no errors
1. Start the application on the new server
    1. \[new server\] Stop the process: `systemctl start mygeotabadapter`. Wait for the command to finish.
1. Verify the app looks good:
    1. \[new server\] View logs: `journalctl -u mygeotabadapter --follow`
    1. Check grafana dashboard
1. Terminate old server
    1. No need to do this immediately, you can wait a bit
    1. Navigate to AWS web console -> EC2 -> Autoscaling
    1. Set the desired, minimum, and maximum capacity to 1.
