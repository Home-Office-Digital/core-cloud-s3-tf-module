# S3 Bucket Lifecycle Configuration Submodule

Internal submodule that renders `aws_s3_bucket_lifecycle_configuration` for a single bucket.

## Purpose

- Keep lifecycle rendering logic in one place.
- Accept strongly typed lifecycle rules.
- Safely render S3 filter shapes based on real filter conditions.

## Inputs

- `bucket_id` (string): Target S3 bucket ID.
- `rules` (list(object)): Lifecycle rule definitions.
- `default_abort_incomplete_multipart_upload_days` (number): Days used by the module's built-in global abort-multipart rule.

See [variables.tf](variables.tf) for the full input schema.

## Rendering behavior

For each rule filter, this module computes a condition count and renders:

- `0` conditions: `filter {}`
- `1` condition: `filter { ... }`
- `>1` conditions: `filter { and { ... } }`

This avoids invalid filter shapes when optional typed attributes are present as `null`.

## Notes

- This module is intended for internal use by the root module.
- This module always creates lifecycle configuration and adds one global catch-all `abort_incomplete_multipart_upload` rule.
