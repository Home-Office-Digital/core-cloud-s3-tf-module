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

variable "external_replication_role_arns" {
  description = "Optional list of source IAM role ARNs allowed to replicate objects into this bucket"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.external_replication_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/.+", arn))
    ])
    error_message = "external_replication_role_arns must contain valid IAM role ARNs."
  }
}

variable "enable_malware_protection" {
  description = "Enable GuardDuty Malware Protection for the primary S3 bucket"
  type        = bool
  default     = false
}

variable "default_abort_incomplete_multipart_upload_days" {
  description = "Number of days after a multipart upload is initiated before the module's enforced global abort rule cancels the incomplete upload."
  type        = number
  default     = 15
}

variable "lifecycle_primary_rules" {
  description = "Lifecycle rules for the primary bucket. Set to [] for no additional user lifecycle rules."
  type = list(object({
    id      = optional(string)
    status  = optional(string)
    enabled = optional(bool)

    filter = optional(object({
      prefix                   = optional(string)
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      tags                     = optional(map(string))
    }))

    expiration = optional(object({
      date                         = optional(string)
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))

    transitions = optional(list(object({
      date          = optional(string)
      days          = optional(number)
      storage_class = string
    })))

    noncurrent_version_expiration = optional(object({
      noncurrent_days           = optional(number)
      newer_noncurrent_versions = optional(number)
    }))

    noncurrent_version_transitions = optional(list(object({
      noncurrent_days           = number
      newer_noncurrent_versions = optional(number)
      storage_class             = string
    })))
  }))

  default = []
}

variable "lifecycle_replica_rules" {
  description = "Lifecycle rules for the replica bucket. Set to [] for no additional user lifecycle rules."
  type = list(object({
    id      = optional(string)
    status  = optional(string)
    enabled = optional(bool)

    filter = optional(object({
      prefix                   = optional(string)
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      tags                     = optional(map(string))
    }))

    expiration = optional(object({
      date                         = optional(string)
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))

    transitions = optional(list(object({
      date          = optional(string)
      days          = optional(number)
      storage_class = string
    })))

    noncurrent_version_expiration = optional(object({
      noncurrent_days           = optional(number)
      newer_noncurrent_versions = optional(number)
    }))

    noncurrent_version_transitions = optional(list(object({
      noncurrent_days           = number
      newer_noncurrent_versions = optional(number)
      storage_class             = string
    })))
  }))

  default = []
}

variable "lifecycle_logs_rules" {
  description = "Lifecycle rules for the logs bucket. Set to [] for no additional user lifecycle rules."
  type = list(object({
    id      = optional(string)
    status  = optional(string)
    enabled = optional(bool)

    filter = optional(object({
      prefix                   = optional(string)
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      tags                     = optional(map(string))
    }))

    expiration = optional(object({
      date                         = optional(string)
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))

    transitions = optional(list(object({
      date          = optional(string)
      days          = optional(number)
      storage_class = string
    })))

    noncurrent_version_expiration = optional(object({
      noncurrent_days           = optional(number)
      newer_noncurrent_versions = optional(number)
    }))

    noncurrent_version_transitions = optional(list(object({
      noncurrent_days           = number
      newer_noncurrent_versions = optional(number)
      storage_class             = string
    })))
  }))

  default = [
    {
      id     = "cc-bucket-lifecycle-rule-logs"
      status = "Enabled"
      filter = {}
      expiration = {
        days = 60
      }
    }
  ]
}
