variable "app_name" {
  description = "The application's name"
  type        = string
  default     = "youtrack-backup"
}

variable "aws_region" {
  description = "AWS region the app will run in"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS access key ID"
  type        = string
  default     = null
}

variable "aws_secret_key" {
  description = "AWS access key (the secret)"
  type        = string
  default     = null
}

variable "b2_application_key" {
  description = "Backblaze Application Key (the secret)"
  type        = string
  default     = null
}

variable "b2_application_key_id" {
  description = "Backblaze Application Key ID"
  type        = string
  default     = null
}

variable "b2_bucket" {
  description = "Backblaze B2 bucket name"
  type        = string
  default     = null
}

variable "backup_enabled" {
  description = "Flag to indicate if the backup should be scheduled"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "When the backup should be executed, min hour day-of-month month day-of-week year"
  type        = string
  default     = "21 06 * * ? *" # Every day at 06:21 UTC
}

variable "cpu" {
  description = "Amount of CPU to be given to the app"
  type        = number
  default     = 200
}

variable "customer" {
  description = "Customer name, used in AWS tags"
  type        = string
}

variable "docker_tag" {
  description = "Tag for the Docker image to be used"
  type        = string
  default     = "latest"
}

variable "keep_count" {
  description = "Number of backup files to keep"
  type        = number
  default     = 0
}

variable "memory" {
  description = "Amount of memory to be given to the app"
  type        = number
  default     = 128
}

variable "tags" {
  description = "Additional tags to be attached to resources"
  type        = map(string)
  default     = {}
}

variable "tf_remote_organization" {
  description = "Terraform organization name"
  type        = string
}

variable "tf_remote_common_workspace" {
  description = "Terraform Cloud workspace that created the VPC, etc."
  type        = string
}

variable "youtrack_token" {
  description = "YouTrack Cloud Permanent Access Token"
  type        = string
  default     = ""
}

variable "youtrack_url" {
  description = "Base URL for the YouTrack Cloud instance to be backed up"
  type        = string
  default     = ""
}

variable "sentry_dsn" {
  description = "Sentry DSN for error tracking"
  type        = string
  sensitive   = true
  default    = ""
}
