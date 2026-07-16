// Mock providers to avoid real AWS/random calls during tests.
mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.cc_assume_role
    values = {
      json = "{}"
    }
  }
}

variables {
  account_id      = "100000000000"
  bucket_name     = "testbucket"
  kms_alias       = "test-kms-key"
  project_name    = "testproject"
  environment     = "test"
  encryption_type = "aws:kms"
  region          = "eu-west-2"
  source-repo     = "github.com/Home-Office-Digital/core-cloud-s3-tf-module"
  email_address   = "test@test"

  tags = {
    Environment      = "test"
    Project          = "test"
    cost-centre      = "CC1000"
    account-code     = "AC1000"
    portfolio-id     = "PF1000"
    project-id       = "PR1000"
    service-id       = "SV1000"
    environment-type = "test"
    owner-business   = "test"
    budget-holder    = "testteam"
    source-repo      = "Home-Office-Digital/core-cloud-s3-tf-module"
    hosting-platform = "test-platform"
  }
}

# Root-module lifecycle tests validate concise lifecycle behavior through
# submodule rendered_rule_ids outputs.

run "validate_no_additional_lifecycle_rules" {
  command = plan

  variables {
    lifecycle_primary_rules = []
    lifecycle_replica_rules = []
    lifecycle_logs_rules    = []
  }

  assert {
    condition     = length(module.lifecycle_primary.rendered_rule_ids) == 1
    error_message = "Primary should render only the built-in global abort rule when input is []"
  }

  assert {
    condition     = length(module.lifecycle_replica.rendered_rule_ids) == 1
    error_message = "Replica should render only the built-in global abort rule when input is []"
  }

  assert {
    condition     = length(module.lifecycle_logs.rendered_rule_ids) == 1
    error_message = "Logs should render only the built-in global abort rule when input is []"
  }

  assert {
    condition     = contains(module.lifecycle_primary.rendered_rule_ids, "cc-default-abort-incomplete-multipart-uploads")
    error_message = "Primary should include the built-in global abort rule"
  }

  assert {
    condition     = contains(module.lifecycle_replica.rendered_rule_ids, "cc-default-abort-incomplete-multipart-uploads")
    error_message = "Replica should include the built-in global abort rule"
  }

  assert {
    condition     = contains(module.lifecycle_logs.rendered_rule_ids, "cc-default-abort-incomplete-multipart-uploads")
    error_message = "Logs should include the built-in global abort rule"
  }
}

run "validate_module_builtin_lifecycle_defaults" {
  command = plan

  assert {
    condition     = length(module.lifecycle_primary.rendered_rule_ids) == 1
    error_message = "Primary should default to only the built-in global abort rule"
  }

  assert {
    condition     = length(module.lifecycle_replica.rendered_rule_ids) == 1
    error_message = "Replica should default to only the built-in global abort rule"
  }

  assert {
    condition     = length(module.lifecycle_logs.rendered_rule_ids) == 2
    error_message = "Logs should include built-in global abort plus default retention"
  }

  assert {
    condition     = contains(module.lifecycle_logs.rendered_rule_ids, "cc-bucket-lifecycle-rule-logs")
    error_message = "Logs should include built-in retention rule"
  }
}

run "validate_mixed_overrides_and_defaults" {
  command = plan

  variables {
    lifecycle_primary_rules = [
      {
        id     = "primary-only-retention"
        status = "Enabled"
        expiration = {
          days = 7
        }
      }
    ]
    lifecycle_replica_rules = [
      {
        id     = "replica-only-retention"
        status = "Enabled"
        expiration = {
          days = 30
        }
      }
    ]
    lifecycle_logs_rules = [
      {
        id     = "logs-only-retention"
        status = "Enabled"
        expiration = {
          days = 30
        }
      }
    ]
  }

  assert {
    condition     = contains(module.lifecycle_primary.rendered_rule_ids, "primary-only-retention")
    error_message = "Primary should include primary-only-retention"
  }

  assert {
    condition     = contains(module.lifecycle_replica.rendered_rule_ids, "replica-only-retention")
    error_message = "Replica should include replica-only-retention"
  }

  assert {
    condition     = contains(module.lifecycle_logs.rendered_rule_ids, "logs-only-retention")
    error_message = "Logs should include logs-only-retention"
  }
}

run "validate_primary_diverse_rule_types" {
  command = plan

  variables {
    lifecycle_primary_rules = [
      {
        id     = "expire-temp"
        status = "Enabled"
        filter = {
          prefix = "tmp/"
        }
        expiration = {
          days = 14
        }
      },
      {
        id     = "analytics-transition"
        status = "Enabled"
        filter = {
          prefix = "analytics/"
        }
        transitions = [
          {
            days          = 30
            storage_class = "STANDARD_IA"
          },
          {
            days          = 90
            storage_class = "GLACIER"
          }
        ]
      },
      {
        id     = "versioned-archive"
        status = "Enabled"
        noncurrent_version_transitions = [
          {
            noncurrent_days = 45
            storage_class   = "STANDARD_IA"
          }
        ]
        noncurrent_version_expiration = {
          noncurrent_days = 120
        }
      }
    ]
    lifecycle_replica_rules = []
    lifecycle_logs_rules    = []
  }

  assert {
    condition     = length(module.lifecycle_primary.rendered_rule_ids) == 4
    error_message = "Primary should include three user rules plus the built-in global abort rule"
  }

  assert {
    condition     = contains(module.lifecycle_primary.rendered_rule_ids, "expire-temp")
    error_message = "Primary should include the expire-temp rule"
  }

  assert {
    condition     = contains(module.lifecycle_primary.rendered_rule_ids, "analytics-transition")
    error_message = "Primary should include the analytics-transition rule"
  }

  assert {
    condition     = contains(module.lifecycle_primary.rendered_rule_ids, "versioned-archive")
    error_message = "Primary should include the versioned-archive rule"
  }
}
