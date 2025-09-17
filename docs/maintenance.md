### OS Updates

OS updates can be performed with minimal downtime, potentially only a few seconds.

1. Update AMI in launch template
    1. The automatic AMI updater runs monthly. If you need to force it, go to Github repository -> actions -> Update AMI -> Run Workflow. This will create a pull request with the latest AMI (if it is newer than the current one)
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

### Application Updates
