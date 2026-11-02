# VWO FME Flutter SDK

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

## Overview

The **VWO Feature Management and Experimentation SDK** (VWO FME Flutter SDK) enables Flutter developers to integrate feature flagging and experimentation into their applications. This SDK provides full control over feature rollout, A/B testing, and event tracking, allowing teams to manage features dynamically and gain insights into user behavior.

## Requirements

The Flutter SDK supports:
- iOS 12.0 or higher
- Android API level 21 or higher

## SDK Installation

Add the VWO FME Flutter SDK to your project's `pubspec.yaml` file:

```yaml
dependencies:
  vwo_fme_flutter_sdk: ^<latestVersion>
```

The latest version of the SDK can be found in [pub.dev](https://pub.dev/packages/vwo_fme_flutter_sdk)

For iOS, install the CocoaPods dependencies by running the command below. Supports iOS version 12.0 and above.

```bash
flutter pub get
```

## Basic Usage

The following example demonstrates initializing the SDK with a VWO account ID and SDK key, setting a user context, checking if a feature flag is enabled, and tracking a custom event.

```dart
import 'package:vwo_fme_flutter_sdk/vwo.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_user_context.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';
import 'package:vwo_fme_flutter_sdk/logger/log_transport.dart';

// Create a custom logger implementation
class DartLogger implements LogTransport {
  @override
  void log(String level, String? message) {
    if (message == null) return;
    print("FME-Flutter: [$level] $message");
  }
}

// Initialize VWO SDK with logger configuration
var transport = <String, dynamic>{};
transport["defaultTransport"] = DartLogger();

var logger = <Map<String, dynamic>>[];
logger.add(transport);

final vwoInitOptions = VWOInitOptions(
  sdkKey: SDK_KEY,
  accountId: ACCOUNT_ID,
  logger: {"level": "TRACE", "transports": logger},
);

// Create VWO instance with the vwoInitOptions
final vwoClient = await VWO.init(vwoInitOptions);

// Create VWOUserContext object
final context = VWOUserContext(
    customVariables: {"key1": 21, "key2":"value"},
    shouldUseDeviceIdAsUserId: true, // Set to true to use device ID as user ID when userId is not provided, this is false by default and need not be passed if not required
);

// Get the GetFlag object for the feature key and context
final featureFlag = await vwoClient?.getFlag(
  featureKey: "feature_key",
  context: context,
);

if (featureFlag != null) {
  // Get the flag value
  final isFeatureFlagEnabled = featureFlag.isEnabled();

  // Get the variable value for the given variable key and default value
  dynamic variable = featureFlag.getVariable("feature_flag_variable", "default-value");
}

// Track the event for the given event name and context
final properties = {"cartvalue": 10};
await vwoClient?.trackEvent(
  eventName: "event-name",
  context: context,
  eventProperties: properties,
);

// Send attributes data
final attributes = {
  "attributeName": "attributeValue"
};
await vwoClient?.setAttribute(
  attributes: attributes,
  context: context,
);
```

## Advanced Configuration Options

To customize the SDK further, additional parameters can be passed to the `init()` API. Here's a table describing each option:

| **Parameter**              | **Description**                                                                                                                                             | **Required** | **Type** | **Example**                     |
|----------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------| ------------ |----------|---------------------------------|
| `accountId`                | VWO Account ID for authentication.                                                                                                                          | Yes          | Integer  | `123456`                        |
| `sdkKey`                   | SDK key corresponding to the specific environment to initialize the VWO SDK Client. You can get this key from VWO Application.                              | Yes          | String   | `'32-alpha-numeric-sdk-key'`    |
| `pollInterval`             | Time interval for fetching updates from VWO servers (in milliseconds).                                                                                      | No           | Integer  | `60000`                         |
| `cachedSettingsExpiryTime` | Controls the duration (in milliseconds) the SDK uses cached settings before fetching new ones.                                                              | No           | Integer  | `60000`                         |
| `cachedDecisionExpiryTime` | Expiry time for cached `getFlag` decisions in milliseconds. `0` means decisions never expire.                                                              | No           | Integer  | `60000`                         |
| `batchMinSize`             | Uploads are triggered when the batch reaches this minimum size.                                                                                             | No           | Integer  | `10`                            |
| `batchUploadTimeInterval`  | Specifies the time interval (in milliseconds) for periodic batch uploads.                                                                                   | No           | Integer  | `60000`                         |
| `shouldTriggerIntegrationCallbackAlways` | When `true`, integration callback fires on every evaluation (including cached decisions). Default (`false`) fires once per unique payload.      | No           | Boolean  | `false`                        |
| `logger`                   | Custom logger configuration for controlling log levels and implementing custom logging behavior.                                                             | No           | Object   | See [Logger](#logger) section   |

### User Context

The `context` object uniquely identifies users and is crucial for consistent feature rollouts. A typical `context` includes an `id` for identifying the user. It can also include other attributes that can be used for targeting and segmentation, such as `customVariables`.

#### Parameters Table

The following table explains all the parameters in the `context` object:

| **Parameter**     | **Description**                                                            | **Required** | **Type** | **Example**                       |
| ----------------- | -------------------------------------------------------------------------- | ------------ | -------- | --------------------------------- |
| `id`              | Unique identifier for the user. Can be null if shouldUseDeviceIdAsUserId is true. | No           | String?  | `'unique_user_id'`                |
| `customVariables` | Custom attributes for targeting.                                           | No           | Object   | `{ age: 25, location: 'US' }`     |
| `shouldUseDeviceIdAsUserId` | When set to true, uses device ID as user ID when userId is not provided. Defaults to false. | No | Boolean | `true` |
| `bucketingSeed`   | Seed used for bucketing instead of `id`. Falls back to `id` if `null` or empty. | No           | String   | `'household-123'`                 |
| `postSegmentationVariables` | Keys from `customVariables` applied as post-segmentation attributes. | No           | List<String> | `['plan', 'country']`             |
| `ipAddress`       | User IP for gateway user-details (sent when gateway is configured). iOS.   | No           | String   | `'1.2.3.4'`                       |

#### Example

```dart
final userContext = VWOUserContext(
    id: USER_ID,
    customVariables: {
        "age": 25,
        "location": "US",
        "plan": "premium"
    },
    postSegmentationVariables: ["plan", "location"],
    bucketingSeed: "stable-seed-123",
    shouldUseDeviceIdAsUserId: false, // Set to true to use device ID as user ID when userId is not provided
);

// Example with null id and device ID as user ID
final userContextWithDeviceId = VWOUserContext(
    customVariables: {
        "age": 25,
        "location": "US"
    },
    shouldUseDeviceIdAsUserId: true, // Set to true to use device ID as user ID when userId is not provided, this is false by default and need not be passed if not required
);
```

### Custom Bucketing Seed

`bucketingSeed` on `VWOUserContext` keeps feature-flag decisions consistent across different users. When a seed is set, the SDK buckets on that seed instead of the user ID, so users who share a seed land on the same variation.

Common uses:

- Household or account-level consistency — everyone on the same account gets the same experience.
- Cross-device consistency — the same logical identity resolves to the same variation even when each device has its own user ID.

#### Behavior

- A non-null, non-empty `bucketingSeed` takes priority over `id` for bucketing.
- `null` or `""` falls back to `id`.
- Forced variations (whitelisted users) still take precedence over the seed.

Example usage:

```dart
// Two different users sharing the same seed receive the same variation
final alice = VWOUserContext(
  id: 'user_alice',
  bucketingSeed: 'household-123',
);
final bob = VWOUserContext(
  id: 'user_bob',
  bucketingSeed: 'household-123',
);

final aliceFlag = await vwoClient?.getFlag(
  featureKey: 'feature_key',
  context: alice,
);
final bobFlag = await vwoClient?.getFlag(
  featureKey: 'feature_key',
  context: bob,
);
// aliceFlag and bobFlag resolve to the same variation
```

### Cached Decision Expiry

`cachedDecisionExpiryTime` on `VWOInitOptions` sets how long a stored `getFlag` decision stays valid, in milliseconds. After it expires, the next `getFlag` call evaluates the flag again. Omit the option, or set it to `0`, and cached decisions never expire.

#### Behavior

- The value is in milliseconds.
- `0` or omitted: stored decisions never expire.
- A positive value: `getFlag` reuses the stored decision until that interval elapses, then evaluates again.

Example usage:

```dart
final options = VWOInitOptions(
  sdkKey: SDK_KEY,
  accountId: ACCOUNT_ID,
  cachedDecisionExpiryTime: 60000, // 1 minute
);
final vwoClient = await VWO.init(options);

final context = VWOUserContext(id: 'user_123');
final flag = await vwoClient?.getFlag(
  featureKey: 'feature_key',
  context: context,
);
// Calls within 1 minute reuse this decision.
// After 1 minute, the next getFlag evaluates again.
```

### Always Trigger Integration Callback

When `shouldTriggerIntegrationCallbackAlways` is `true`, the integration callback runs on every evaluation, including decisions served from cache.

```dart
final options = VWOInitOptions(
  sdkKey: SDK_KEY,
  accountId: ACCOUNT_ID,
  shouldTriggerIntegrationCallbackAlways: true,
);
final vwoClient = await VWO.init(options);
```

### Basic Feature Flagging

Feature Flags serve as the foundation for all testing, personalization, and rollout rules within FME.
To implement a feature flag, first use the `getFlag` API to retrieve the flag configuration.
The `getFlag` API provides a simple way to check if a feature is enabled for a specific user and access its variables.

| Parameter    | Description                                                      | Required | Type   | Example                                                                               |
| ------------ |------------------------------------------------------------------| -------- | ------ |---------------------------------------------------------------------------------------|
| `featureKey` | Unique identifier of the feature flag                            | Yes      | String | `'new_checkout'`                                                                      |
| `context`    | Object containing user identification and contextual information | Yes      | Object | `VWOUserContext()`                                                                    |

Example usage:

```dart
final featureFlag = await vwoClient?.getFlag(
  featureKey: "featureKey",
  context: context,
);

if (featureFlag != null) {
  // Get the flag value
  final isFeatureFlagEnabled = featureFlag.isEnabled();

  // Get the variable value for the given variable key and default value
  final variable = featureFlag.getVariable("feature_flag_variable", "default-value") as String;
}
```

### Custom Event Tracking

Feature flags can be enhanced with connected metrics to track key performance indicators (KPIs) for your features. These metrics help measure the effectiveness of your testing rules by comparing control versus variation performance, and evaluate the impact of personalization and rollout campaigns. Use the `trackEvent` API to track custom events like conversions, user interactions, and other important metrics:

| Parameter         | Description                                                            | Required | Type   | Example                                     |
| ----------------- | ---------------------------------------------------------------------- | -------- | ------ |---------------------------------------------|
| `eventName`       | Name of the event you want to track                                    | Yes      | String | `'purchase_completed'`                      |
| `context`         | Object containing user identification and other contextual information | Yes      | Object | `VWOUserContext()`                          |
| `eventProperties` | Additional properties/metadata associated with the event               | No       | Object | `{"amount": 10}`                            |

Example usage:

```dart
final context = VWOUserContext(
    id: userId
);
final properties = {"cartvalue": 10};

await vwoClient.trackEvent(
  eventName: "event-name",
  context: context,
  eventProperties: properties,
);
```

### Pushing Attributes

User attributes provide rich contextual information about users, enabling powerful personalization. The `setAttribute` method provides a simple way to associate these attributes with users in VWO for advanced segmentation. Here's what you need to know about the method parameters:

| Parameter        | Description                                                            | Required | Type   | Example                 |
|------------------|------------------------------------------------------------------------| -------- |--------|-------------------------|
| `attributes`     | Map of attribute key and value to be set                               | Yes      | Object | `{"price": 99}`         |
| `context`        | Object containing user identification and other contextual information | Yes      | Object | `VWOUserContext()`      |

Example usage:

```dart
final context = VWOUserContext(
    id: userId
);
final attributes = {"price": 99};
await vwoClient?.setAttribute(
  attributes: attributes,
  context: context,
);
```

### Polling Interval Adjustment

The `pollInterval` is an optional parameter that allows the SDK to automatically fetch and update settings from the VWO server at specified intervals. Setting this parameter ensures your application always uses the latest configuration.

```dart

final vwoInitOptions = VWOInitOptions(
        sdkKey: SDK_KEY,
        accountId: ACCOUNT_ID,
        pollInterval: 60000
)    

// Create VWO instance with the vwoInitOptions
final vwoClient = await VWO.init(vwoInitOptions);
```

### Logger

VWO by default logs all `ERROR` level messages to the console. To gain more control over VWO's logging behavior, you can use the `logger` parameter in the `init` configuration.

| **Parameter** | **Description**                        | **Required** | **Type** | **Example**           |
| ------------- | -------------------------------------- | ------------ | -------- | --------------------- |
| `level`       | Log level to control verbosity of logs | Yes          | String   | `TRACE`               |
| `transports`  | Custom logger implementation           | No           | Object   | See example below     |

#### Example: Implement custom logger

The `transports` parameter allows you to implement custom logging behavior by providing your own logging functions. You can define handlers for different log levels (TRACE, DEBUG, INFO, WARN, ERROR) to process log messages according to your needs.

```dart
// Create a custom logger implementation
class DartLogger implements LogTransport {
  @override
  void log(String level, String? message) {
    if (message == null) return;
    print("FME-Flutter: [$level] $message");
  }
}

// Configure logger in VWO initialization
var transport = <String, dynamic>{};
transport["defaultTransport"] = DartLogger();

var logger = <Map<String, dynamic>>[];
logger.add(transport);

final vwoInitOptions = VWOInitOptions(
  sdkKey: SDK_KEY,
  accountId: ACCOUNT_ID,
  logger: {"level": "TRACE", "transports": logger},
);

final vwoClient = await VWO.init(vwoInitOptions);
```

## Authors

* [Nabin Niroula](https://github.com/xyznaveen)
* [Swapnil Chaudhari](https://github.com/swapnilWingify)

### Version History

The version history tracks changes, improvements and bug fixes in each version. For a full history, see the [CHANGELOG.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CHANGELOG.md).

## Contributing

We welcome contributions to improve this SDK! Please read our [contributing guidelines](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CONTRIBUTING.md) before submitting a PR.

## Code of Conduct

[Code of Conduct](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CODE_OF_CONDUCT.md)

## License

[Apache License, Version 2.0](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/LICENSE)

Copyright (c) 2024-2025 Wingify Software Pvt. Ltd. 
