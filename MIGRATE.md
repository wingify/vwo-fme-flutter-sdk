# Migrate to the Wingify FME Flutter SDK

This guide explains how to adopt the **Wingify** public API (`package:wingify_fme_flutter_sdk`) on the Flutter FME SDK. Existing **VWO** integrations (`package:vwo_fme_flutter_sdk`) continue to work without changes.

For installation, device support, and advanced configuration, see [README.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/README.md).

---

## Overview

The Flutter FME SDK is published as two packages built from the **same source** at the same version:

| Package | Public API |
| --- | --- |
| `wingify_fme_flutter_sdk` | `Wingify`, `WingifyInitOptions`, `WingifyUserContext` (recommended for new apps) |
| `vwo_fme_flutter_sdk` | `VWO`, `VWOInitOptions`, `VWOUserContext` (legacy, deprecated) |

Pick **one** dependency in your `pubspec.yaml` — do not add both.

The VWO package remains available on [pub.dev](https://pub.dev/packages/vwo_fme_flutter_sdk). New integrations should use the Wingify package on [pub.dev](https://pub.dev/packages/wingify_fme_flutter_sdk). When you initialize through `Wingify`, the SDK uses Wingify edge/collect endpoints and Wingify-branded behavior. Event and API payload field names (for example `_vwo_meta`) are unchanged for compatibility with the FME platform.

---

## Wingify API — implementation guide

Use package `wingify_fme_flutter_sdk` and public types under that package.

Legacy `vwo_fme_flutter_sdk` APIs remain supported and are marked `@Deprecated` with hints pointing to Wingify equivalents.

### Implementation steps

1. **Add the dependency** — use only the Wingify package:

   ```yaml
   dependencies:
     wingify_fme_flutter_sdk: ^<latestVersion>
   ```

   The latest version can be found on [pub.dev](https://pub.dev/packages/wingify_fme_flutter_sdk).

2. **Import the SDK:**

   ```dart
   import 'package:wingify_fme_flutter_sdk/wingify_fme_flutter_sdk.dart';
   ```

3. **Initialize** — create `WingifyInitOptions`, set `sdkKey` and `accountId`, then call `Wingify.init()`:

   ```dart
   final initOptions = WingifyInitOptions(
     sdkKey: SDK_KEY,
     accountId: ACCOUNT_ID,
   );
   final wingifyClient = await Wingify.init(initOptions);
   ```

4. **Build user context** — create `WingifyUserContext` with a user `id` (or enable `shouldUseDeviceIdAsUserId` for anonymous users):

   ```dart
   final context = WingifyUserContext(
     id: "unique_user_id",
     customVariables: {"key1": 21, "key2": "value"},
   );
   ```

5. **Evaluate flags** — call `getFlag`. Results are `GetFlag`:

   ```dart
   final featureFlag = await wingifyClient?.getFlag(
     featureKey: "feature_key",
     context: context,
   );

   if (featureFlag != null) {
     final isEnabled = featureFlag.isEnabled();
     final variable = featureFlag.getVariable("feature_flag_variable", "default-value");
   }
   ```

6. **Track and attribute** — use `trackEvent`, `setAttribute`, and `setAlias` on the initialized client:

   ```dart
   await wingifyClient?.trackEvent(
     eventName: "event_name",
     context: context,
     eventProperties: {"cartvalue": 10},
   );

   await wingifyClient?.setAttribute(
     attributes: {"attributeName": "attributeValue"},
     context: context,
   );

   await wingifyClient?.setAlias(context: context, alias: "alias_id");
   ```

7. **Reuse instances (optional)** — `Wingify.getInstance(accountId: ..., sdkKey: ...)` returns a cached client; call `clearInstance()` on that client to reset.

### Full example

```dart
import 'package:wingify_fme_flutter_sdk/wingify_fme_flutter_sdk.dart';

final initOptions = WingifyInitOptions(
  sdkKey: SDK_KEY,
  accountId: ACCOUNT_ID,
  pollInterval: 60000,
);

final wingifyClient = await Wingify.init(initOptions);

final context = WingifyUserContext(
  id: "unique_user_id",
  customVariables: {"age": 25, "location": "US"},
);

final featureFlag = await wingifyClient?.getFlag(
  featureKey: "feature_key",
  context: context,
);

if (featureFlag != null && featureFlag.isEnabled()) {
  final variable = featureFlag.getVariable("variable_key", "default-value");
}

await wingifyClient?.trackEvent(
  eventName: "purchase_completed",
  context: context,
  eventProperties: {"cartvalue": 120},
);

await wingifyClient?.setAttribute(
  attributes: {"price": 99},
  context: context,
);

// Cached instance for the same account/sdkKey
final cached = Wingify.getInstance(accountId: ACCOUNT_ID, sdkKey: SDK_KEY);
```

---

## Public API mapping

| Legacy (`vwo_fme_flutter_sdk`) | Wingify (`wingify_fme_flutter_sdk`) |
| --- | --- |
| `VWO` | `Wingify` |
| `VWO.init()` | `Wingify.init()` |
| `VWO.getInstance()` | `Wingify.getInstance()` |
| `VWOInitOptions` | `WingifyInitOptions` |
| `VWOInitOptions.vwo_meta` | `WingifyInitOptions.platformMeta` |
| `VWOUserContext` | `WingifyUserContext` |
| `package:vwo_fme_flutter_sdk/vwo.dart` (+ model imports) | `package:wingify_fme_flutter_sdk/wingify_fme_flutter_sdk.dart` |

### Wingify entry points

| Component | Type |
| --- | --- |
| SDK client | `Wingify` |
| Init options | `WingifyInitOptions` |
| User context | `WingifyUserContext` |
| Feature flag result | `GetFlag` |
| Custom logger | `LogTransport` |
| Mobile Insights session | `FmeConfig.setSessionData()` |

`Wingify` supports the same operations as `VWO`: `init`, `getFlag`, `trackEvent`, `setAttribute`, `setAlias`, and instance cache helpers (`getInstance`, `clearInstance`).

### Shared types

The `GetFlag`, `Variable`, `LogTransport`, and `FmeConfig` types are shared. The Wingify package re-exports them from `wingify_fme_flutter_sdk.dart`; on the VWO package, import them from their existing paths (for example `vwo/models/get_flag.dart`).

Legacy `VWOInitOptions` and `VWOUserContext` extend the Wingify types; behavior and wire format are the same. Only the Dart property name for init metadata differs (`vwo_meta` vs `platformMeta`); the native bridge still sends `_vwo_meta` for both brands.

The instance methods (`getFlag`, `trackEvent`, `setAttribute`, `setAlias`, `clearInstance`) have identical signatures on `VWO` and `Wingify`.

---

## Legacy VWO API

The following remain available for existing apps:

- `VWO` and its public methods
- `VWOInitOptions`, `VWOUserContext`, `GetFlag`
- Package `vwo_fme_flutter_sdk`

Legacy types are marked `@Deprecated` with hints to migrate to Wingify equivalents. You can migrate imports at your own pace; no breaking change is required to stay on `vwo_fme_flutter_sdk`.

---

## Runtime behavior (Wingify mode)

When you initialize through `Wingify` (not `VWO`), you may notice:

| Area | Behavior |
| --- | --- |
| Network | Settings and events use Wingify hosts (`edge.wingify.net`, `collect.wingify.net`) |
| Native bridge | Routes through the Wingify native API (`useWingifyApi: true`) |
| Log messages | User-visible log text uses Wingify branding where appropriate |

Event and API payload field names (for example `_vwo_meta`) are unchanged for compatibility with the FME platform.

---

## Migrating from `vwo_fme_flutter_sdk` to `wingify_fme_flutter_sdk`

1. Replace the dependency with `wingify_fme_flutter_sdk` at the same version you use today.
2. Update imports to `package:wingify_fme_flutter_sdk/wingify_fme_flutter_sdk.dart`.
3. Rename `VWO` → `Wingify`, `VWOInitOptions` → `WingifyInitOptions`, `VWOUserContext` → `WingifyUserContext`.
4. If you set init metadata, rename `vwo_meta` → `platformMeta` on `WingifyInitOptions`.
5. Run your existing tests — SDK behavior for flags, events, and attributes is unchanged.

---

## Related documents

| Document | Content |
| --- | --- |
| [README.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/README.md) | Installation and advanced configuration |
| [CHANGELOG.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CHANGELOG.md) | Version history |
| [CONTRIBUTING.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CONTRIBUTING.md) | Contributing guidelines |
| [CODE_OF_CONDUCT.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CODE_OF_CONDUCT.md) | Code of conduct |

## Authors

* [Nabin Niroula](https://github.com/xyznaveen)
* [Swapnil Chaudhari](https://github.com/swapnilWingify)

## Version History

The version history tracks changes, improvements and bug fixes in each version. For a full history, see the [CHANGELOG.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CHANGELOG.md).

## Contributing

We welcome contributions to improve this SDK! Please read our [contributing guidelines](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CONTRIBUTING.md) before submitting a PR.

## Code of Conduct

[Code of Conduct](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CODE_OF_CONDUCT.md)

## License

[Apache License, Version 2.0](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/LICENSE)

Copyright (c) 2024-2026 Wingify Software Pvt. Ltd.
