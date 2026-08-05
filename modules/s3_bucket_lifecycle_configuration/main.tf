terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0"
    }
  }
}

locals {
  # Build lifecycle_rules by preserving each input rule and adding a computed filter condition count.
  # The added filter_condition_count drives which filter shape to render:
  # 0 -> filter {}, 1 -> filter { ... }, >1 -> filter { and { ... } }.
  # Example rendered value shape:
  # lifecycle_rules = [
  #   {
  #     id = "example-rule"
  #     filter = {
  #       prefix = "tmp/"
  #       tags   = { team = "core" }
  #     }
  #     filter_condition_count = 2
  #   }
  # ]
  lifecycle_rules = [
    for rule in var.rules : merge(rule, {
      filter_condition_count = rule.filter == null ? 0 : (
        length([
          for value in [
            rule.filter.prefix,
            rule.filter.object_size_greater_than,
            rule.filter.object_size_less_than,
          ] : value if value != null
        ]) +
        length(coalesce(rule.filter.tags, {}))
      )
    })
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  # checkov:skip=CKV_AWS_300: False positive with dynamic lifecycle rules. This submodule enforces a global catch-all abort rule for incomplete multipart uploads.
  bucket = var.bucket_id

  # Enforce one global abort-multipart rule.
  rule {
    id     = "cc-default-abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.default_abort_incomplete_multipart_upload_days
    }
  }

  dynamic "rule" {
    for_each = local.lifecycle_rules

    content {
      id     = rule.value.id
      status = try(rule.value.enabled ? "Enabled" : "Disabled", tobool(rule.value.status) ? "Enabled" : "Disabled", title(lower(rule.value.status)), "Enabled")

      dynamic "expiration" {
        for_each = (
          rule.value.expiration != null
          ? [rule.value.expiration]
          : []
        )

        content {
          date                         = expiration.value.date
          days                         = expiration.value.days
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      dynamic "transition" {
        for_each = (
          rule.value.transitions != null
          ? rule.value.transitions
          : []
        )

        content {
          date          = transition.value.date
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = (
          rule.value.noncurrent_version_expiration != null
          ? [rule.value.noncurrent_version_expiration]
          : []
        )

        content {
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = (
          rule.value.noncurrent_version_transitions != null
          ? rule.value.noncurrent_version_transitions
          : []
        )

        content {
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      # Emit an empty filter block when no filter is provided or no conditions are set.
      dynamic "filter" {
        for_each = (
          rule.value.filter_condition_count == 0
          ? [true]
          : []
        )

        content {}
      }

      # Emit a single-condition filter (prefix, one size bound, or a single tag).
      dynamic "filter" {
        for_each = (
          rule.value.filter_condition_count == 1
          ? [rule.value.filter]
          : []
        )

        content {
          prefix                   = try(filter.value.prefix, null)
          object_size_greater_than = try(filter.value.object_size_greater_than, null)
          object_size_less_than    = try(filter.value.object_size_less_than, null)

          dynamic "tag" {
            for_each = [for tag_key, tag_value in coalesce(filter.value.tags, {}) : {
              key   = tag_key
              value = tag_value
            }]

            content {
              key   = tag.value.key
              value = tag.value.value
            }
          }
        }
      }

      # Emit an AND filter when multiple conditions are provided.
      dynamic "filter" {
        for_each = (
          rule.value.filter_condition_count > 1
          ? [rule.value.filter]
          : []
        )

        content {
          and {
            prefix                   = try(filter.value.prefix, null)
            object_size_greater_than = try(filter.value.object_size_greater_than, null)
            object_size_less_than    = try(filter.value.object_size_less_than, null)
            tags                     = length(coalesce(filter.value.tags, {})) > 0 ? coalesce(filter.value.tags, {}) : null
          }
        }
      }
    }
  }
}
