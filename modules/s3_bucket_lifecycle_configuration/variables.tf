variable "bucket_id" {
  description = "S3 bucket ID for lifecycle configuration"
  type        = string
}

variable "default_abort_incomplete_multipart_upload_days" {
  description = "Number of days after a multipart upload is initiated before the module's enforced global abort rule cancels the incomplete upload"
  type        = number
  default     = 15
}

variable "rules" {
  description = "Lifecycle rule list"
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
