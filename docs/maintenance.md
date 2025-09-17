### OS Updates

OS updates can be performed with minimal downtime, potentially only a few seconds.

1. mark Run terraform apply (preferably through CI/CD) which will dynamically update the launch template with the latest AWS AMI.
1. Disable automatic start up -> In AWS web console, go to SSM parameter store and set "/mygeotab-api-adapter/prod/enable_auto_start"

### Application Updates
