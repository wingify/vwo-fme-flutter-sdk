# VWO FME Flutter SDK

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

## SDK Installation

Add below dependency in your project's `pubspec.yaml`.

```yaml
vwo_fme_flutter_sdk: <latest version>
```

Latest version of SDK can be found in [pub.dev](https://pub.dev/packages/vwo-fme-flutter-sdk)

For iOS, install the CocoaPods dependencies by running below command. Supports iOS version 12.0 and above.

```bash
cd ios && pod install
```

## Basic Usage

```dart
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_context.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';
import 'package:vwo_fme_flutter_sdk/vwo.dart';

// Initialize the VWO SDK and get the initialization status.
var initOptions = VWOInitOptions(sdkKey: sdkKey, accountId: accountId);

VWO? _vwo = await VWO.init(initOptions);
// Define the user context with user ID and custom variables.
final vwoContext = VWOContext(
  userId: userId,
  customVariables: {'number': 12, 'key2': 'value2'},
  ipAddress: "1.0.0.1",
  userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (HTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
);

// Get the feature flag result.
final GetFlag? flagResult = await _vwo?.getFlag(
flagName: flagName,
vwoContext: vwoContext,
);

// Get the isEnabled status of the flag.
bool isEnabled=flagResult.isEnabled();

// Get a specific variable from the flag, with a default value.
dynamic color = flagResult.getVariable('feature_flag_variable_key', 'default_value');

// Get all variables associated with the flag.
dynamic variables = flagResult.getVariables();

// Track an event with the given event name and user context.
final trackingResult = await _vwo?.trackEvent(
  eventName: eventName,
  context: userContext,
);

// Set a user attribute with the given key, value, and user context.
final success = await _vwo?.setAttribute(
  attributeKey: attributeName,
  attributeValue: attributeValue,
  context: userContext,
);
```

## Authors

* [Swapnil Chaudhari](https://github.com/swapnilWingify)

## Changelog

Refer [CHANGELOG.md](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CHANGELOG.md)

## Contributing

Please go through our [contributing guidelines](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CONTRIBUTING.md)

## Code of Conduct

[Code of Conduct](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/CODE_OF_CONDUCT.md)

## License

[Apache License, Version 2.0](https://github.com/wingify/vwo-fme-flutter-sdk/blob/master/LICENSE)

Copyright 2024 Wingify Software Pvt. Ltd.
