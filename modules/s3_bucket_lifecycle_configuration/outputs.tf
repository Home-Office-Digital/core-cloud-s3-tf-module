output "rendered_rule_ids" {
  description = "Rule IDs rendered into aws_s3_bucket_lifecycle_configuration"
  value       = [for rule in aws_s3_bucket_lifecycle_configuration.this.rule : rule.id]
}