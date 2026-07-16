variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = ""
}

variable "kms_alias" {
  description = "KMS key alias for bucket encryption"
  type        = string
  nullable    = false
}

variable "enable_versioning" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to be applied to the bucket"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      contains(keys(var.tags), "account-code"),
      contains(keys(var.tags), "cost-centre"),
      contains(keys(var.tags), "portfolio-id"),
      contains(keys(var.tags), "project-id"),
      contains(keys(var.tags), "service-id"),
      contains(keys(var.tags), "environment-type"),
      contains(keys(var.tags), "owner-business"),
      contains(keys(var.tags), "budget-holder"),
      contains(keys(var.tags), "source-repo"),
      contains(keys(var.tags), "hosting-platform")
    ])
    error_message = "Tags must include all mandatory fields."
  }

}

variable "encryption_type" {
  description = "The server-side encryption algorithm to use. Valid values are 'aws:kms' or 'AES256'. AES256 is for SSE-S3"
  type        = string
  default     = "aws:kms"

  validation {
    condition     = contains(["aws:kms", "AES256"], var.encryption_type)
    error_message = "The encryption_type must be either 'aws:kms' or 'AES256'."
  }
}

variable "account_id" {
  description = "The AWS Account ID."
  type        = string
}

variable "lifecycle_expiration_days" {
  description = "Number of days to keep s3 objects before expiration"
  type        = number
  default     = 30
}

variable "lifecycle_expiration_days_logs" {
  description = "Number of days to keep s3 objects in logging bucket before expiration"
  type        = number
  default     = 60
}


variable "days_after_initiation" {
  description = "Specifies the number of days after initiating a multipart upload when the multipart upload must be completed."
  default     = 15
  type        = number
}

variable "replication_rule" {
  type        = string
  description = "The name of the replication rule applied to S3"
  default     = "cc-default-replication-rule"
}

variable "mfa_delete" {
  type        = string
  default     = "Disabled"
  description = "Enable MFA delete for either changing the versioning state of your bucket or permanently deleting an object version. Value must be 'Enabled' or 'Disabled'."
}

variable "email_address" {
  type        = string
  default     = ""
  description = "Shared project mailbox."
}

variable "enable_malware_protection" {
  description = "Enable GuardDuty Malware Protection for the primary S3 bucket"
  type        = bool
  default     = false
}
