locals {
  app_env          = data.terraform_remote_state.common.outputs.app_env
  app_environment  = data.terraform_remote_state.common.outputs.app_environment
  app_name_and_env = "${var.app_name}-${local.app_env}"
  ecs_cluster_arn  = data.terraform_remote_state.common.outputs.ecs_cluster_id
  name_tag_suffix  = "${var.app_name}-${var.customer}-${local.app_environment}"
}

/*
 * Create cloudwatch log group for app logs
 */
resource "aws_cloudwatch_log_group" "ytbackup" {
  name              = local.app_name_and_env
  retention_in_days = 60

  tags = {
    name = "cloudwatch_log_group-${local.name_tag_suffix}"
  }
}

/*
 * Create task definition for file system backup
 */
locals {
  task_def = templatefile("${path.module}/task-def-yt-backup.tftpl",
    {
      app_name              = var.app_name
      aws_access_key_id     = var.aws_access_key
      aws_access_key        = var.aws_secret_key
      aws_region            = var.aws_region
      b2_application_key_id = var.b2_application_key_id
      b2_application_key    = var.b2_application_key
      b2_bucket             = var.b2_bucket
      cpu                   = var.cpu
      cw_log_group          = aws_cloudwatch_log_group.ytbackup.name
      cw_stream_prefix      = local.app_name_and_env
      docker_image          = "ghcr.io/sil-org/youtrack-backup"
      docker_tag            = var.docker_tag
      keep_count            = var.keep_count
      memory                = var.memory
      yt_token              = var.youtrack_token
      yt_url                = var.youtrack_url
      sentry_dsn            = var.sentry_dsn
    }
  )
}

resource "aws_ecs_task_definition" "this" {
  family                = "${var.app_name}-${local.app_env}"
  container_definitions = local.task_def
  task_role_arn         = ""
  network_mode          = "bridge"
}

module "task" {
  source  = "sil-org/scheduled-ecs-task/aws"
  version = "~> 1.0"

  name                   = local.app_name_and_env
  event_rule_description = "Start YouTrack backup on cron schedule"
  enable                 = var.backup_enabled
  event_schedule         = "cron(${var.backup_schedule})"
  ecs_cluster_arn        = local.ecs_cluster_arn
  task_definition_arn    = aws_ecs_task_definition.this.arn
}
