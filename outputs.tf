output "bucket_id" {
  description = "The id of the main bucket"
  value       = aws_s3_bucket.this.id
  sensitive   = true
}

output "bucket_arn" {
  description = "The ARN of the main bucket"
  value       = aws_s3_bucket.this.arn
  sensitive   = true
}

output "kms_key_id" {
  description = "The KMS Key ID of the bucket"
  value       = aws_kms_key.s3.id
  sensitive   = true
}

output "kms_key_arn" {
  description = "The KMS Key ARN of the bucket"
  value       = aws_kms_key.s3.arn
  sensitive   = true
}