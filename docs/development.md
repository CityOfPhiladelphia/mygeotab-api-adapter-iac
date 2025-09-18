# Development

When developing new features, it is best to test the full functionality before merging to `main`. This is because the CI integration, while thorough for verifying the Terraform code itself, does not verify that the actual code will work as intended.

Since we only budgeted a single environment, the prod environment, any development would either require downtime, or would require a dev environment to be spun up temporarily. Please work with Ryan Weast.

## Getting credentials locally

Check out the credentials that are pulled from Keeper in the [.github/workflows](.github/workflows) files. Set those up locally.

## Developing AWS / Terraform code

Just use `terraform apply` locally from your development machine.

## Developing server configuration

To test server configuration (the server/ folder), push your code to a non-main branch and update the `build_branch` parameter in terraform (in terraform/env/ folder) to that branch name. Then, use Terraform apply to update the launch template to pull from that new build branch, then replace the server. Since we only have the `prod` environment, this would cause outage. Make sure to change the `build_branch` back to main before merging the changes to main.
