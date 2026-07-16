# Changelog

All notable changes to this project will be documented in this file. This will provide a record of all notable module updates with each new release. Semantic versioning (https://semver.org/) must be adhered to for all Core Cloud modules.

## [1.1.1] - 2026-02-16

### Added

- Initial tag created for Core Cloud S3 Terraform module

## [0.0.2] - 2026-02-17

### Added

- Adding default s3 access logging and replication configuration.

## [0.0.3] - 2026-02-18

### Changed

- Updating module README with recommendations and usage.

## [0.0.4] - 2026-02-19

### Changed

- Updating README & Adding default access settings for replica and logging buckets & Adding module tests.

## [0.0.5] - 2026-02-23

### Added

- Adding required tags to IAM Role.

## [0.0.6] - 2026-02-24

### Added

- Adding required mandatory tag.

## [0.0.7] - 2026-02-24

### Changed

- Adjusting module README usage tagging.

## [0.1.7] - 2026-02-24

### Changed

- Adjusting module README usage tagging.

## [0.1.8] - 2026-02-27

### Added

- Adding s3 standard Terraform tests.

## [0.1.9] - 2026-03-27

### Added

- Adding Dependabot workflow.

## [0.1.10] - 2026-03-27

### Changed

- Adjusting Dependabot workflow Slack message.

## [0.1.11] - 2026-03-30

### Added

- Adding weekly Terraform init and validate workflow.

## [0.1.12] - 2026-04-01

### Changed

- Updating CHANGELOG Format.

## [0.2.5] - 2026-05-20

### Added

- Added Mandatory tag and updated Terraform tests.

### Changed

- Updating Terraform minimum version.

## [0.3.0] - 2026-08-02

### Added

- Adding GuardDuty Malware Protection support for S3.

## [1.0.0] - 2026-08-05

### Breaking

- Lifecycle inputs moved to flexible per-bucket rule lists.
- Removed legacy lifecycle inputs: lifecycle_expiration_days, lifecycle_expiration_days_logs, days_after_initiation.
- By default, lifecycle_primary_rules and lifecycle_replica_rules are empty ([]), and lifecycle_logs_rules contains one default rule (id = cc-bucket-lifecycle-rule-logs, expiration.days = 60).
- Global abort multipart rule is always enforced per bucket via default_abort_incomplete_multipart_upload_days (default 15).
