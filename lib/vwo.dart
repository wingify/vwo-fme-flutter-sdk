/*
 * Copyright 2024-2025 Wingify Software Pvt. Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_user_context.dart';
import 'package:vwo_fme_flutter_sdk/vwo_fme_flutter_sdk_method_channel.dart';

import 'vwo_fme_flutter_sdk_platform_interface.dart';

/// The main class for interacting with the VWO Flutter SDK.
///
/// This class provides methods for initializing the SDK, getting feature flags,
/// tracking events, and setting user attributes.
class VWO {

  VwoFmeFlutterSdkPlatform? _fmePlugin;

  /// Initializes the VWO SDK.
  ///
  /// This method should be called before any other VWO methods.
  ///
  /// [options] The initialization options for the VWO SDK.
  ///
  /// Returns a [Future] that resolves to a [VWO] instance if successful, or `null` if an error occurs.
  static Future<VWO?> init(VWOInitOptions options) async {
    try {
      var sdkPlugin = await MethodChannelVwoFmeFlutterSdk.init(options);
      var fmeSdk = VWO();
      fmeSdk._fmePlugin = sdkPlugin;
      return fmeSdk;
    } catch (e) {
      if (e is PlatformException) {
        logMessage("VWO: Error: ${e.message ?? ""}");
      } else {
        logMessage("VWO: Error: $e");
      }
      return null;
    }
  }

  /// Gets the value of a feature flag.
  ///
  /// [featureKey] The name of the feature flag.
  /// [context] The user context for evaluating the flag.
  ///
  /// Returns a [Future] that resolves to a [GetFlag] object containing the flag value and other metadata.
  Future<GetFlag?> getFlag({
    required String featureKey,
    required VWOUserContext context,
  }) async {
    try {
      return _fmePlugin?.getFlag(featureKey: featureKey, userContext: context);
    } catch (e) {
      String details;
      if (e is PlatformException) {
        details = e.message ?? '';
      } else {
        details = e.toString();
      }
      logMessage('VWO: Failed to retrieve feature flag $details');
      return null;
    }
  }

  /// Tracks an event.
  ///
  /// [eventName] The name of the event.
  /// [context] The VWO context for the event.
  /// [eventProperties] Optional properties associated with the event.
  ///
  /// Returns a [Future] that resolves to a map indicating the success status of the event tracking.
  Future<Map<String, bool>?> trackEvent({
    required String eventName,
    required VWOUserContext context,
    Map<String, dynamic>? eventProperties,
  }) async {
    try {
      return _fmePlugin?.trackEvent(
          eventName: eventName,
          userContext: context,
          eventProperties: eventProperties);
    } catch (e) {
      String details;
      if (e is PlatformException) {
        details = e.message ?? '';
      } else {
        details = e.toString();
      }
      logMessage('VWO: Failed to track event $details');
      return null;
    }
  }

  /// Sets a user attribute.
  ///
  /// [attributeKey] The key of the attribute.
  /// [attributeValue] The value of the attribute.
  /// [context] The user context for the attribute.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of setting the attribute.
  Future<bool>? setAttribute({
    required Map<String, dynamic> attributes,
    required VWOUserContext context,
  }) async {
    try {
      final plugin = _fmePlugin;
      if (plugin == null) return false;

      return plugin.setAttribute(
          attributes: attributes,
          userContext: context);
    } catch (e) {
      String details;
      if (e is PlatformException) {
        details = e.message ?? '';
      } else {
        details = e.toString();
      }
      logMessage('VWO: Failed to set attribute $details');
      return false;
    }
  }

  static void logMessage(String message) {
    // Only prints in debug
    if (kDebugMode) {
      print(message);
    }
  }
}
