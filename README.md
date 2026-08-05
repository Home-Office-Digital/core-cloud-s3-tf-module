# Core Cloud S3 Module

This S3 Child Module is written and maintained by the Core Cloud Platform team and includes the following checks and scans:
Terraform validate, Terraform fmt, TFLint, Checkov scan, Sonarqube scan and Semantic versioning - MAJOR.MINOR.PATCH.

## Module Structure

<strong>---| .github</strong>  
&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [dependabot.yaml](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/.github/dependabot.yaml)</strong> - Checks repository daily for any dependency updates and raises a PR into main for review.  \
&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| workflows</strong> \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [pull-request-sast.yaml](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/.github/workflows/pull-request-sast.yaml)</strong> - Workflow containing terraform init, terraform validate, terraform fmt - referencing Core Cloud TFLint, Checkov scan and Sonarqube scan shared workflows. Runs on pull request and merge to main branch. \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [pull-request-semver-label-check.yaml](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/.github/workflows/pull-request-semver-label-check.yaml)</strong> - Verifies all PRs to main raised in the module must have an appropriate semver label: major/minor/patch. \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [pull-request-semver-tag-merge.yaml](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/.github/workflows/pull-request-semver-tag-merge.yaml)</strong> - Calculates the new semver value depending on the PR label and tags the repository with the correct tag. \
<strong>---| tests</strong> \
&nbsp;&nbsp;<strong>---| [s3.tftest.hcl](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/tests/s3.tftest.hcl)</strong> \
<strong>---| [CHANGELOG.md](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/CHANGELOG.md)</strong> - Contains all significant changes in relation to a semver tag made to this module. \
<strong>---| [CODEOWNERS](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/CODEOWNERS)</strong> \
<strong>---| [CODE_OF_CONDUCT](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/CODE_OF_CONDUCT.md)</strong> \
<strong>---| [CONTRIBUTING.md](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/CONTRIBUTING.md)</strong>  \
<strong>---| [LICENSE.md](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/LICENSE.md)</strong>  \
<strong>---| [README.md](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/README.md)</strong>  \
<strong>---| [main.tf](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/main.tf)</strong> - Contains the main set of configuration for this module.  \
<strong>---| [outputs.tf](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/outputs.tf)</strong> - Contain the output definitions for this module.  \
<strong>---| [variables.tf](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/variables.tf)</strong> - Contains the declarations for module variables, all variables have a defined type and short description outlining their purpose.  \
<strong>---| [versions.tf](https://github.com/Home-Office-Digital/core-cloud-s3-tf-module/blob/CCL-7090/versions.tf)</strong> - Contains the providers needed by the module.  

## Terraform Tests

All module tests are located in the test/ folder and uses Terraform test. These are written and maintained by the Core Cloud QA team.  \
The test files found in this folder validate the S3 module configuration.  \
Please refer to the [Official Hashicorp Terraform Test documentation](https://developer.hashicorp.com/terraform/language/tests).

## Usage 

This module creates and manages three buckets: a primary bucket, a replica bucket, and a logs bucket.

Recommended settings:

- Enable versioning.
- Adhere to Core Cloud mandatory tags.
- Opt into mfa delete when possible.
- S3 Encryption type must be 'aws:kms' or 'AES256'.

- Note: S3 Event notifications, access logging and replication is enabled by default when using this module. All public access will be blocked for the S3 bucket and all connections to S3 buckets created by this module use TLS.
- Note: GuardDuty Malware Protection is optional and disabled by default.

## GuardDuty Malware Protection

You can make uploaded objects in the primary bucket be scanned for malware by setting `enable_malware_protection = true` to turn on [Amazon GuardDuty Malware Protection for S3](https://docs.aws.amazon.com/guardduty/latest/ug/gdu-malware-protection-s3.html). Amazon GuardDuty must already be enabled in the bucket's AWS account and region.

Enabling `enable_malware_protection` also enables EventBridge notifications for the primary bucket so S3 object events can be sent to GuardDuty Malware Protection for S3.

GuardDuty Malware Protection for S3 uses an AWS-managed EventBridge rule for this integration.

This module does not create or manage account-level GuardDuty resources.

See the below example configuration:

```
terraform {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-s3-tf-module.git?ref={tag}"
}

inputs = {

  bucket_name                = "test-1"
  kms_alias                  = "test-kms-key"
  project_name               = "xxx"
  environment                = "test"
  encryption_type            = "aws:kms"
  account_id                 = "xxxxx"
  email_address              = "<project-shared-mailbox>"
  enable_malware_protection  = true

  # Tags for all resources
  tags = {
    cost-centre      = "xxx"
    account-code     = "xxx"
    portfolio-id     = "xxx"
    project-id       = "xxx"
    service-id       = "xxx"
    environment-type = "test"
    owner-business   = "xxx"
    budget-holder    = "xxx"
    source-repo      = "xxx"
  }
}

```

## Lifecycle Configuration

Lifecycle is configured independently per bucket using:

- `lifecycle_primary_rules`
- `lifecycle_replica_rules`
- `lifecycle_logs_rules`

Usage:

- Set a non-empty list to fully define lifecycle rules for that bucket.
- The module always enforces one global catch-all abort-multipart rule for each bucket.

Rule support includes filters (`prefix`, size bounds, tags), expiration, transitions,
and noncurrent-version transitions/expiration.

### Lifecycle Example

Override primary lifecycle:

```hcl
lifecycle_primary_rules = [
  {
    id     = "primary-hot-tiering"
    status = "Enabled"
    filter = {
      prefix = "hot/"
      tags = {
        data_classification = "internal"
      }
    }
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 60
        storage_class = "GLACIER"
      }
    ]
  },
  {
    id     = "primary-version-archive"
    status = "Enabled"
    noncurrent_version_transitions = [
      {
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      },
      {
        noncurrent_days = 90
        storage_class   = "GLACIER"
      }
    ]
  }
]

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.88.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.57.1 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_lifecycle_logs"></a> [lifecycle\_logs](#module\_lifecycle\_logs) | ./modules/s3_bucket_lifecycle_configuration | n/a |
| <a name="module_lifecycle_primary"></a> [lifecycle\_primary](#module\_lifecycle\_primary) | ./modules/s3_bucket_lifecycle_configuration | n/a |
| <a name="module_lifecycle_replica"></a> [lifecycle\_replica](#module\_lifecycle\_replica) | ./modules/s3_bucket_lifecycle_configuration | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_guardduty_malware_protection_plan.cc_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_malware_protection_plan) | resource |
| [aws_iam_policy.cc_s3_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cc_s3_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cc_s3_replication_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cc_s3_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.bucket_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.s3_replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_logging.bucket_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_ownership_controls.bucket_ownership](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.cc_deny_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.cc_deny_http_replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.cc_bucket_replication_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.s3_logs_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.s3_replica_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_sns_topic.event_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.topic-email-subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_iam_policy_document.cc_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_assume_role_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_https_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_https_policy_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_https_policy_replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_logging_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_logs_combined_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_s3_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cc_s3_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS Account ID. | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket | `string` | `""` | no |
| <a name="input_default_abort_incomplete_multipart_upload_days"></a> [default\_abort\_incomplete\_multipart\_upload\_days](#input\_default\_abort\_incomplete\_multipart\_upload\_days) | Number of days after a multipart upload is initiated before the module's enforced global abort rule cancels the incomplete upload. | `number` | `15` | no |
| <a name="input_email_address"></a> [email\_address](#input\_email\_address) | Shared project mailbox. | `string` | `""` | no |
| <a name="input_enable_malware_protection"></a> [enable\_malware\_protection](#input\_enable\_malware\_protection) | Enable GuardDuty Malware Protection for the primary S3 bucket | `bool` | `false` | no |
| <a name="input_enable_versioning"></a> [enable\_versioning](#input\_enable\_versioning) | Enable versioning for the bucket | `bool` | `true` | no |
| <a name="input_encryption_type"></a> [encryption\_type](#input\_encryption\_type) | The server-side encryption algorithm to use. Valid values are 'aws:kms' or 'AES256'. AES256 is for SSE-S3 | `string` | `"aws:kms"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_kms_alias"></a> [kms\_alias](#input\_kms\_alias) | KMS key alias for bucket encryption | `string` | n/a | yes |
| <a name="input_lifecycle_logs_rules"></a> [lifecycle\_logs\_rules](#input\_lifecycle\_logs\_rules) | Lifecycle rules for the logs bucket. Set to [] for no additional user lifecycle rules. | <pre>list(object({<br/>    id      = optional(string)<br/>    status  = optional(string)<br/>    enabled = optional(bool)<br/><br/>    filter = optional(object({<br/>      prefix                   = optional(string)<br/>      object_size_greater_than = optional(number)<br/>      object_size_less_than    = optional(number)<br/>      tags                     = optional(map(string))<br/>    }))<br/><br/>    expiration = optional(object({<br/>      date                         = optional(string)<br/>      days                         = optional(number)<br/>      expired_object_delete_marker = optional(bool)<br/>    }))<br/><br/>    transitions = optional(list(object({<br/>      date          = optional(string)<br/>      days          = optional(number)<br/>      storage_class = string<br/>    })))<br/><br/>    noncurrent_version_expiration = optional(object({<br/>      noncurrent_days           = optional(number)<br/>      newer_noncurrent_versions = optional(number)<br/>    }))<br/><br/>    noncurrent_version_transitions = optional(list(object({<br/>      noncurrent_days           = number<br/>      newer_noncurrent_versions = optional(number)<br/>      storage_class             = string<br/>    })))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "expiration": {<br/>      "days": 60<br/>    },<br/>    "filter": {},<br/>    "id": "cc-bucket-lifecycle-rule-logs",<br/>    "status": "Enabled"<br/>  }<br/>]</pre> | no |
| <a name="input_lifecycle_primary_rules"></a> [lifecycle\_primary\_rules](#input\_lifecycle\_primary\_rules) | Lifecycle rules for the primary bucket. Set to [] for no additional user lifecycle rules. | <pre>list(object({<br/>    id      = optional(string)<br/>    status  = optional(string)<br/>    enabled = optional(bool)<br/><br/>    filter = optional(object({<br/>      prefix                   = optional(string)<br/>      object_size_greater_than = optional(number)<br/>      object_size_less_than    = optional(number)<br/>      tags                     = optional(map(string))<br/>    }))<br/><br/>    expiration = optional(object({<br/>      date                         = optional(string)<br/>      days                         = optional(number)<br/>      expired_object_delete_marker = optional(bool)<br/>    }))<br/><br/>    transitions = optional(list(object({<br/>      date          = optional(string)<br/>      days          = optional(number)<br/>      storage_class = string<br/>    })))<br/><br/>    noncurrent_version_expiration = optional(object({<br/>      noncurrent_days           = optional(number)<br/>      newer_noncurrent_versions = optional(number)<br/>    }))<br/><br/>    noncurrent_version_transitions = optional(list(object({<br/>      noncurrent_days           = number<br/>      newer_noncurrent_versions = optional(number)<br/>      storage_class             = string<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_lifecycle_replica_rules"></a> [lifecycle\_replica\_rules](#input\_lifecycle\_replica\_rules) | Lifecycle rules for the replica bucket. Set to [] for no additional user lifecycle rules. | <pre>list(object({<br/>    id      = optional(string)<br/>    status  = optional(string)<br/>    enabled = optional(bool)<br/><br/>    filter = optional(object({<br/>      prefix                   = optional(string)<br/>      object_size_greater_than = optional(number)<br/>      object_size_less_than    = optional(number)<br/>      tags                     = optional(map(string))<br/>    }))<br/><br/>    expiration = optional(object({<br/>      date                         = optional(string)<br/>      days                         = optional(number)<br/>      expired_object_delete_marker = optional(bool)<br/>    }))<br/><br/>    transitions = optional(list(object({<br/>      date          = optional(string)<br/>      days          = optional(number)<br/>      storage_class = string<br/>    })))<br/><br/>    noncurrent_version_expiration = optional(object({<br/>      noncurrent_days           = optional(number)<br/>      newer_noncurrent_versions = optional(number)<br/>    }))<br/><br/>    noncurrent_version_transitions = optional(list(object({<br/>      noncurrent_days           = number<br/>      newer_noncurrent_versions = optional(number)<br/>      storage_class             = string<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_mfa_delete"></a> [mfa\_delete](#input\_mfa\_delete) | Enable MFA delete for either changing the versioning state of your bucket or permanently deleting an object version. Value must be 'Enabled' or 'Disabled'. | `string` | `"Disabled"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_replication_rule"></a> [replication\_rule](#input\_replication\_rule) | The name of the replication rule applied to S3 | `string` | `"cc-default-replication-rule"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to the bucket | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | The ARN of the main bucket |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | The id of the main bucket |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The KMS Key ARN of the bucket |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The KMS Key ID of the bucket |
<!-- END_TF_DOCS -->