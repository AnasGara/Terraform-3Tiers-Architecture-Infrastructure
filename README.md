# Three-tier AWS architecture study

Terraform experiments covering VPC networking, frontend/backend EC2 instances,
an application load balancer, PostgreSQL RDS, DNS, backup, IAM, and WAF.

## Current status

This is an unfinished architecture study, **not a deployable reference**.
Do not run `terraform apply` against an AWS account yet. Known blockers:

- `cartoInfrastructure.tf` duplicates resources, variables, and provider configuration
  already split across the other root files.
- `maint.tf` references local module directories that are absent and duplicates outputs.
- `route_tables.tf` uses `count.index` in an uncounted route table.
- `iam.tf` references a missing policy file and creates a long-lived access key.
- The legacy WAF example uses an uppercase `.Tf` suffix, so Terraform ignores it;
  a regional WAFv2 implementation and ALB association are needed.
- AMI IDs, PostgreSQL engine settings, DNS placeholders, and network routes need review.
- EC2 bootstrap/application deployment, TLS, and live acceptance checks are absent.

For the maintained modular implementation, see
[Scalable AWS Infrastructure](https://github.com/AnasGara/AWS---Scalable-infrastructure---Terraform).

## Credentials and state

The split RDS resource now requires the sensitive `db_password` input (16+ characters).
Supply it using `TF_VAR_db_password` through your shell or secret manager. Do not
paste passwords into tracked files. Terraform's sensitive marking hides console
output but does not encrypt state: use an access-controlled encrypted remote backend
before any deployment. Local state, plans, private keys, and `.tfvars` are ignored.

An old example password remains in Git history and should be treated as exposed.
Treat it as compromised if it was ever used; rotate it in the actual database.
Resolving these blockers and running provider-backed validation is the next milestone.
