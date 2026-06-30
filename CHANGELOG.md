# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.55.0] - 2026-06-30

### Added

- Added user tracking support: sends a `vwo_feTrackUsage` event when user tracking is enabled for the account and no variation-shown impression was dispatched for the evaluation.

## [1.50.0] - 2026-06-01

This release introduces Wingify as the primary SDK branding and package namespace, while keeping existing VWO integrations fully supported.

Both pub packages ship the **same library source** at the same version — pick one; do not add both:

| Package | Public API |
| --- | --- |
| `wingify_fme_flutter_sdk` | `Wingify`, `WingifyInitOptions`, `WingifyUserContext` (recommended for new apps) |
| `vwo_fme_flutter_sdk` | `VWO`, `VWOInitOptions`, `VWOUserContext` (legacy, deprecated) |

For a full migration guide, see [MIGRATE.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/MIGRATE.md).

### Added

- **Wingify public API** — use `Wingify`, `WingifyInitOptions`, and `WingifyUserContext` from the `wingify_fme_flutter_sdk` package as the recommended entry point for new integrations.
- **Wingify pub package** — `wingify_fme_flutter_sdk` publishes the same Dart API as the legacy VWO package.

  ```dart
  // Wingify (recommended)
  import 'package:wingify_fme_flutter_sdk/wingify_fme_flutter_sdk.dart';

  final options = WingifyInitOptions(
    sdkKey: SDK_KEY,
    accountId: ACCOUNT_ID,
  );

  final wingifyClient = await Wingify.init(options);

  final context = WingifyUserContext(id: "user-123");
  final flag = await wingifyClient?.getFlag(
    featureKey: "feature-key",
    context: context,
  );
  ```

### Changed

- The SDK implementation now routes through the Wingify native APIs when initialized via `Wingify`.
- Log messages and documentation have been updated to reflect Wingify branding.
- When initialized through `Wingify`, settings and events use Wingify hosts (`edge.wingify.net`, `collect.wingify.net`).
- Aligned the Flutter SDK version with the native SDKs (1.50.0) and upgraded the underlying native dependencies (Android `com.wingify.sdk:wingify-fme-android-sdk:1.50.0`, iOS `Wingify-FME 1.50.0`).
- No breaking changes for existing integrations — server event names, payload keys, and runtime behavior remain compatible with the VWO platform.

### Deprecated

The following VWO types in `vwo_fme_flutter_sdk` are deprecated but continue to work without modification:

| Deprecated (still supported) | Use instead |
| --- | --- |
| `VWO` | `Wingify` |
| `VWOInitOptions` | `WingifyInitOptions` |
| `VWOUserContext` | `WingifyUserContext` |
| `VWOInitOptions.vwo_meta` | `WingifyInitOptions.platformMeta` |
| Package `vwo_fme_flutter_sdk` | Package `wingify_fme_flutter_sdk` |

Existing code does not need to change immediately. We recommend adopting the Wingify API for new projects and migrating when convenient:

```dart
// Still supported — no action required today
import 'package:vwo_fme_flutter_sdk/vwo.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_user_context.dart';

final options = VWOInitOptions(
  sdkKey: SDK_KEY,
  accountId: ACCOUNT_ID,
);

final vwoClient = await VWO.init(options);

final context = VWOUserContext(id: "user-123");
await vwoClient?.getFlag(featureKey: "feature-key", context: context);
```

**Migration tip:** Replace `VWO` → `Wingify`, `VWOInitOptions` → `WingifyInitOptions`, `VWOUserContext` → `WingifyUserContext`, update imports to `package:wingify_fme_flutter_sdk/wingify_fme_flutter_sdk.dart`, and rename `vwo_meta` → `platformMeta` if used. Method signatures and SDK behavior are unchanged.

## [1.9.0] - 2026-04-28

### Added

- Multi-instance / multi-account for different credentials within a single application
- When invalid credentials entered, do not retry API calls
- Support to use Device ID if `context.id` is not available
- Support to set user Aliasing
- Introduced holdout group support for feature flags and events, including holdout settings in the configuration, SDK-side holdout evaluation, and exclusion of users in holdout groups from feature rollouts and experiments.

## [1.8.2] - 2025-12-19

### Fixed

- Fixed a bug validating settings when json type variable contains array of objects
- Fixed issue where `getVariable()` and `getVariables()` returned fallback/empty values when fetching user data from storage for rollout rule.

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
