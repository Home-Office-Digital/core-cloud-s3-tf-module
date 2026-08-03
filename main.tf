resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_key_policy" "bucket_kms_policy" {
  key_id = aws_kms_key.s3.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "bucket_kms_policy",
    "Statement" : [
      {
        "Sid" : "EnableIAMUserPermissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.s3.id
}

resource "aws_sns_topic" "event_topic" {
  name              = "${var.project_name}-${var.bucket_name}-${var.environment}-topic"
  kms_master_key_id = "alias/aws/sns"
  tags              = local.common_tags

  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:${var.region}:${var.account_id}:${var.project_name}-${var.bucket_name}-${var.environment}-topic",
        "Condition":{
          "StringEquals":{"aws:SourceAccount":"${var.account_id}"},
          "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.this.arn}"}
        }      
    }]
}
POLICY
}

resource "aws_sns_topic_subscription" "topic-email-subscription" {
  topic_arn = aws_sns_topic.event_topic.arn
  protocol  = "email"
  endpoint  = var.email_address
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.bucket_name}-${var.environment}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status     = var.enable_versioning ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.encryption_type == "aws:kms" ? aws_kms_key.s3.arn : null
      sse_algorithm     = var.encryption_type
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.this.id
  eventbridge = var.enable_malware_protection

  topic {
    topic_arn = aws_sns_topic.event_topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "cc-bucket-lifecycle-rule"
    status = "Enabled"
    filter {}
    expiration {
      days = var.lifecycle_expiration_days
    }
  }

  rule {
    id     = "cc-abort-incomplete-multipart-uploads"
    status = "Enabled"

    # No filter → applies to all multipart uploads
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.days_after_initiation
    }
  }
}

data "aws_iam_policy_document" "cc_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cc_s3_replication_role" {
  name               = "${var.project_name}-${var.bucket_name}-${var.environment}-replica-role"
  assume_role_policy = data.aws_iam_policy_document.cc_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "cc_s3_replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.this.arn]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.this.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${aws_s3_bucket.s3_replica.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_replication" {
  name   = "${var.project_name}-${var.bucket_name}-${var.environment}-replica-policy"
  policy = data.aws_iam_policy_document.cc_s3_replication.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  role       = aws_iam_role.cc_s3_replication_role.name
  policy_arn = aws_iam_policy.s3_replication.arn
}

resource "aws_s3_bucket" "s3_replica" {
  bucket = "${var.project_name}-${var.bucket_name}-${var.environment}-replica"
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "replica" {
  bucket = aws_s3_bucket.s3_replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "s3_replica_versioning" {
  bucket = aws_s3_bucket.s3_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  bucket = aws_s3_bucket.s3_replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.encryption_type == "aws:kms" ? aws_kms_key.s3.arn : null
      sse_algorithm     = var.encryption_type
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "replica" {
  bucket = aws_s3_bucket.s3_replica.id

  rule {
    id     = "cc-bucket-lifecycle-rule-replica"
    status = "Enabled"
    filter {}
    expiration {
      days = var.lifecycle_expiration_days
    }
  }

  rule {
    id     = "cc-abort-incomplete-multipart-uploads-replica"
    status = "Enabled"

    # No filter → applies to all multipart uploads
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.days_after_initiation
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "cc_bucket_replication_rule" {
  depends_on = [aws_s3_bucket_versioning.s3_replica_versioning]
  bucket     = aws_s3_bucket.this.id
  role       = aws_iam_role.cc_s3_replication_role.arn
  rule {
    id = var.replication_rule
    filter {}
    destination {
      bucket        = aws_s3_bucket.s3_replica.arn
      storage_class = "STANDARD_IA"

      metrics {
        status = "Enabled"
      }
    }
    delete_marker_replication {
      status = "Enabled"
    }
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "cc_assume_role_malware_protection" {
  count = var.enable_malware_protection ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["malware-protection-plan.guardduty.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cc_s3_malware_protection" {
  count = var.enable_malware_protection ? 1 : 0

  name               = "${var.project_name}-${var.bucket_name}-${var.environment}-malware-role"
  assume_role_policy = data.aws_iam_policy_document.cc_assume_role_malware_protection[0].json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "cc_s3_malware_protection" {
  count = var.enable_malware_protection ? 1 : 0

  statement {
    sid    = "AllowManagedRuleToSendS3EventsToGuardDuty"
    effect = "Allow"
    actions = [
      "events:PutRule",
      "events:DeleteRule",
      "events:PutTargets",
      "events:RemoveTargets",
    ]
    resources = [
      "arn:aws:events:${var.region}:${var.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*",
    ]

    condition {
      test     = "StringLike"
      variable = "events:ManagedBy"
      values   = ["malware-protection-plan.guardduty.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowGuardDutyToMonitorEventBridgeManagedRule"
    effect = "Allow"
    actions = [
      "events:DescribeRule",
      "events:ListTargetsByRule",
    ]
    resources = [
      "arn:aws:events:${var.region}:${var.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*",
    ]
  }

  statement {
    sid    = "AllowPostScanTag"
    effect = "Allow"
    actions = [
      "s3:PutObjectTagging",
      "s3:GetObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:GetObjectVersionTagging",
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    sid    = "AllowEnableS3EventBridgeEvents"
    effect = "Allow"
    actions = [
      "s3:PutBucketNotification",
      "s3:GetBucketNotification",
    ]
    resources = [
      aws_s3_bucket.this.arn,
    ]
  }

  statement {
    sid    = "AllowPutValidationObject"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/malware-protection-resource-validation-object",
    ]
  }

  statement {
    sid    = "AllowCheckBucketOwnership"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.this.arn,
    ]
  }

  statement {
    sid    = "AllowMalwareScan"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    sid    = "AllowKMSForValidationAndScan"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      aws_kms_key.s3.arn,
    ]
  }
}

resource "aws_iam_policy" "cc_s3_malware_protection" {
  count = var.enable_malware_protection ? 1 : 0

  name   = "${var.project_name}-${var.bucket_name}-${var.environment}-malware-policy"
  policy = data.aws_iam_policy_document.cc_s3_malware_protection[0].json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cc_s3_malware_protection" {
  count = var.enable_malware_protection ? 1 : 0

  role       = aws_iam_role.cc_s3_malware_protection[0].name
  policy_arn = aws_iam_policy.cc_s3_malware_protection[0].arn
}

resource "aws_guardduty_malware_protection_plan" "cc_s3" {
  count = var.enable_malware_protection ? 1 : 0

  role = aws_iam_role.cc_s3_malware_protection[0].arn

  protected_resource {
    s3_bucket {
      bucket_name = aws_s3_bucket.this.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = local.common_tags
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-${var.bucket_name}-${var.environment}-logs"
  tags   = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.encryption_type == "aws:kms" ? aws_kms_key.s3.arn : null
      sse_algorithm     = var.encryption_type
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "s3_logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "cc-bucket-lifecycle-rule-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = var.lifecycle_expiration_days_logs
    }
  }

  rule {
    id     = "cc-abort-incomplete-multipart-uploads-logs"
    status = "Enabled"

    # No filter → applies to all multipart uploads
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.days_after_initiation
    }
  }
}

data "aws_iam_policy_document" "cc_logging_bucket_policy" {
  statement {
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.logs.bucket
  policy = data.aws_iam_policy_document.cc_logging_bucket_policy.json
}

resource "aws_s3_bucket_logging" "bucket_logging" {
  bucket        = aws_s3_bucket.this.bucket
  target_bucket = aws_s3_bucket.logs.bucket
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

data "aws_iam_policy_document" "cc_https_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cc_deny_http" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.cc_https_policy.json
}

data "aws_iam_policy_document" "cc_https_policy_replica" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    resources = [
      "${aws_s3_bucket.s3_replica.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cc_deny_http_replica" {
  bucket = aws_s3_bucket.s3_replica.id
  policy = data.aws_iam_policy_document.cc_https_policy_replica.json
}

data "aws_iam_policy_document" "cc_https_policy_logs" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    resources = [
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cc_deny_http_logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.cc_https_policy_logs.json
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}