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
  container_def = jsonencode([{
    image     = "ghcr.io/sil-org/youtrack-backup:${var.docker_tag}"
    name      = "youtrack-backup"
    essential = true
    cpu       = var.cpu
    memory    = var.memory

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ytbackup.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = local.app_name_and_env
      }
    }

    environment = [
      {
        name  = "APP_NAME"
        value = var.app_name
      },
      {
        name  = "AWS_REGION"
        value = var.aws_region
      },
      {
        name  = "B2_APPLICATION_KEY_ID"
        value = var.b2_application_key_id
      },
      {
        name  = "B2_APPLICATION_KEY"
        value = var.b2_application_key
      },
      {
        name  = "B2_BUCKET"
        value = var.b2_bucket
      },
      {
        name  = "KEEP_COUNT"
        value = tostring(var.keep_count)
      },
      {
        name  = "YT_TOKEN"
        value = var.youtrack_token
      },
      {
        name  = "YT_URL"
        value = var.youtrack_url
      },
      {
        name  = "SENTRY_DSN"
        value = var.sentry_dsn
      },
    ]
  }])
}

resource "aws_ecs_task_definition" "this" {
  family                = "${var.app_name}-${local.app_env}"
  container_definitions = local.container_def
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
