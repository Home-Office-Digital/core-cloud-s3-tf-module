# KMS Key policy test

# Import shared provider configuration for local testing
# This allows tests to run without real AWS credentials

provider "aws" {
  region                      = "eu-west-2"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
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

run "kms_policy_test" {
  command = plan

  assert {
    condition     = jsondecode(aws_kms_key_policy.bucket_kms_policy.policy)["Statement"][0]["Sid"] == "EnableIAMUserPermissions"
    error_message = "KMS policy must contain the Enable IAM User Permissions statement."
  }
  assert {
    condition     = jsondecode(aws_kms_key_policy.bucket_kms_policy.policy)["Statement"][0]["Action"] == "kms:*"
    error_message = "KMS policy must allow kms:* actions."
  }
}
