# Run youtrack-backup via schedule in existing AWS ECS Cluster
Creates the infrastructure on AWS to run a backup of the YouTrack Cloud
database to a Backblaze B2 bucket on a scheduled basis.

## Required setup
* Obtain an AWS Access key.
* Obtain a Terraform Cloud access token.
* Obtain a Backblaze Application Key.
* Create a Backblaze B2 bucket.

See [youtrack-backup](https://github.com/sil-org/youtrack-backup) for details.

The Terraform remote state is built by a private workspace and is responsible for managing:

* IAM role
* VPC - Subnets, NAT, IG, etc.
* Security Groups for Cloudflare, etc.
* ECS Cluster
* ASG - Scales automatically based on ECS reservations
* ALB - Shared ALB, all services should register listeners/target groups
* CloudTrail
* Amazon Certificate Manager certs
