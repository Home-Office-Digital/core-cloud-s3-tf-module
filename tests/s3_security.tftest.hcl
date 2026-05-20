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


run "validate_kms_encryption" {
  command = plan

  variables {
    encryption_type = "aws:kms"
  }

  assert {
    condition     = tolist(aws_s3_bucket_server_side_encryption_configuration.this.rule)[0].apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Encryption algorithm must be aws:kms when encryption_type is aws:kms"
  }

  # Can't check kms_master_key_id directly as it references computed aws_kms_key.s3.arn
  # Instead, verify KMS key will be created
  assert {
    condition     = aws_kms_key.s3.description == "KMS key for S3 bucket encryption"
    error_message = "KMS key must be created when using aws:kms encryption"
  }

}

run "validate_aes256_encryption" {
  command = plan

  variables {
    encryption_type = "AES256"
  }

  assert {
    condition     = tolist(aws_s3_bucket_server_side_encryption_configuration.this.rule)[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Encryption algorithm must be AES256 when encryption_type is AES256"
  }

}

run "validate_public_access_block_all_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls must be enabled for security compliance"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "block_public_policy must be enabled for security compliance"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == true
    error_message = "ignore_public_acls must be enabled for security compliance"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "restrict_public_buckets must be enabled for security compliance"
  }
}

run "validate_encryption_always_enabled" {
  command = plan

  # Test that encryption is configured regardless of type
  assert {
    condition     = length(tolist(aws_s3_bucket_server_side_encryption_configuration.this.rule)) > 0
    error_message = "Server-side encryption must always be configured"
  }

  assert {
    condition     = contains(["aws:kms", "AES256"], tolist(aws_s3_bucket_server_side_encryption_configuration.this.rule)[0].apply_server_side_encryption_by_default[0].sse_algorithm)
    error_message = "Encryption algorithm must be either aws:kms or AES256"
  }
}
