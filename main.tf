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
      docker_image          = "silintl/youtrack-backup"
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

/*
 * Create role for scheduled running of backup task definitions.
 */
resource "aws_iam_role" "ecs_events" {
  name = "ecs_events-${local.app_name_and_env}"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC

}

resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  name = "ecs_events_run_task_with_any_role"
  role = aws_iam_role.ecs_events.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "${aws_ecs_task_definition.this.arn_without_revision}:*"
        }
    ]
}
DOC

}

/*
 * CloudWatch configuration to start file system backup.
 */
resource "aws_cloudwatch_event_rule" "this" {
  name                = local.app_name_and_env
  description         = "Start YouTrack backup on cron schedule"
  is_enabled          = var.backup_enabled
  schedule_expression = "cron(${var.backup_schedule})"

  tags = {
    app_name = var.app_name
    app_env  = local.app_env
  }
}

resource "aws_cloudwatch_event_target" "b2_backup" {
  target_id = "run-${local.app_name_and_env}"
  rule      = aws_cloudwatch_event_rule.this.name
  arn       = local.ecs_cluster_arn
  role_arn  = aws_iam_role.ecs_events.arn

  ecs_target {
    task_count          = 1
    launch_type         = "EC2"
    task_definition_arn = aws_ecs_task_definition.this.arn
  }
}
