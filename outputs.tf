output "backup_schedule" {
  description = "The backup schedule"
  value       = var.backup_enabled ? var.backup_schedule : ""
}
