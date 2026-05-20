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
  source-repo     = "github.com/UKHomeOffice/core-cloud-s3-tf-module"
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
    source-repo      = "UKHomeOffice/core-cloud-s3-tf-module"
    hosting-platform = "test-platform"
  }
}

run "validate_mandatory_tags_on_bucket" {
  command = plan

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "cost-centre")
    error_message = "cost-centre tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "account-code")
    error_message = "account-code tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "portfolio-id")
    error_message = "portfolio-id tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "project-id")
    error_message = "project-id tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "service-id")
    error_message = "service-id tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "environment-type")
    error_message = "environment-type tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "owner-business")
    error_message = "owner-business tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "budget-holder")
    error_message = "budget-holder tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "source-repo")
    error_message = "source-repo tag must be present on S3 bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "hosting-platform")
    error_message = "hosting-platform tag must be present on S3 bucket"
  }
}

run "validate_tag_values" {
  command = plan

  variables {
    environment  = "test"
    project_name = "test"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "test"
    error_message = "Environment tag must match the environment variable"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Project"] == "test"
    error_message = "Project tag must match the project_name variable"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag must be set to 'terraform'"
  }
}

run "validate_additional_tags_merged" {
  command = plan

  variables {
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
      source-repo      = "UKHomeOffice/core-cloud-s3-tf-module"
      hosting-platform = "test-platform"
      CustomTag        = "CustomValue"
    }
  }

  # Verify additional tags from var.tags are merged
  assert {
    condition     = aws_s3_bucket.this.tags["cost-centre"] == "CC1000"
    error_message = "Additional tags from var.tags must be merged into bucket tags"
  }

  assert {
    condition     = can(aws_s3_bucket.this.tags["CustomTag"])
    error_message = "Custom tags from var.tags must be present on bucket"
  }
}

run "validate_kms_key_tags" {
  command = plan

  # Verify KMS key also gets tagged
  assert {
    condition     = contains(keys(aws_kms_key.s3.tags), "Environment")
    error_message = "KMS key must have Environment tag"
  }

  assert {
    condition     = contains(keys(aws_kms_key.s3.tags), "Project")
    error_message = "KMS key must have Project tag"
  }

  assert {
    condition     = aws_kms_key.s3.tags["ManagedBy"] == "terraform"
    error_message = "KMS key ManagedBy tag must be 'terraform'"
  }
}

run "validate_environment_values" {
  command = plan

  variables {
    environment = "test"
  }

  assert {
    condition     = contains(["test"], aws_s3_bucket.this.tags["Environment"])
    error_message = "Environment tag should be: test"
  }
}
