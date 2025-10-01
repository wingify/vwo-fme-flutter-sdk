# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.1] - 2025-10-01

### Fixed
- Bugfix for user count not increasing on dashboard

## [1.8.0] - 2025-09-03

### Changed

- Updated SDK's usage data upload logic to aggregate in single account

## [1.7.2] - 2025-08-22

### Changed

- Resolved an issue where the iOS SDK was incorrectly identifying the device type for iPhones.

## [1.7.1] - 2025-08-22

### Added

- Added unit tests for enhanced SDK stability.

## [1.7.0] - 2025-08-14

### Added

- Added support for sending a one-time SDK initialization event to VWO server as part of health-check milestones.

## [1.6.4] - 2025-07-25

### Added

- Send the SDK name and version in the events and batching call to VWO as query parameters.

## [1.6.3] - 2025-07-24

### Added

- Send the SDK name and version in the settings call to VWO as query parameters.

## [1.6.0] - 2025-05-09

### Added

- Added the ability to collect usage data to help guide future enhancements and debugging.

### Changed

- Improved the README for better clarity.
- Code refactored for syntax consistency with other SDKs.

## [1.5.0] - 2025-03-18

### Added

- Added support to use DACDN as a substitute for the Gateway Service.

## [1.4.0] - 2025-03-12

### Added
- Support for storing impression events while the device is offline, ensuring no data loss. These events are batched and seamlessly synchronized with VWO servers once the device reconnects to the internet.
- Online event batching allows synchronization of impression events while the device is online. This feature can be configured by setting either the minimum batch size or the batch upload time interval during SDK initialization.
- Support for sending multiple attributes at once.
- Support to use external logger provided in dart code
- Support for configuring SDK when linking with VWO Mobile Insights SDK. This can be configured by setting session data received via callback from Mobile Insights SDK

## [1.1.0] - 2024-12-23

### Changed

- First release of VWO Feature Management and Experimentation capabilities.