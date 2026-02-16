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
  int? _accountId;
  String? _sdkKey;

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
      fmeSdk._accountId = options.accountId;
      fmeSdk._sdkKey = options.sdkKey;
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

  /// Gets an existing VWO instance by accountId and sdkKey.
  ///
  /// This method retrieves an instance that was previously initialized.
  /// The instance must have been initialized using [init] before calling this method.
  ///
  /// [accountId] The account ID of the VWO instance.
  /// [sdkKey] The SDK key of the VWO instance.
  ///
  /// Returns a [VWO] instance if found, or `null` if the instance doesn't exist.
  static VWO? getInstance({
    required int accountId,
    required String sdkKey,
  }) {
    try {
      var fmeSdk = VWO();
      fmeSdk._fmePlugin = VwoFmeFlutterSdkPlatform.instance;
      fmeSdk._accountId = accountId;
      fmeSdk._sdkKey = sdkKey;
      return fmeSdk;
    } catch (e) {
      logMessage("VWO: Error getting instance: $e");
      return null;
    }
  }

  /// Gets the value of a feature flag.
  ///
  /// [featureKey] The name of the feature flag.
  /// [context] The user context for evaluating the flag.
  ///
  /// Returns a [Future] that resolves to a [GetFlag] object containing the flag value and other metadata.
  Future<GetFlag?> getFlag(
      {required String featureKey, required VWOUserContext context}) async {
    try {
      return _fmePlugin?.getFlag(
        featureKey: featureKey,
        userContext: context,
        accountId: _accountId,
        sdkKey: _sdkKey,
      );
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
  Future<Map<String, bool>?> trackEvent(
      {required String eventName,
      required VWOUserContext context,
      Map<String, dynamic>? eventProperties}) async {
    try {
      return _fmePlugin?.trackEvent(
        eventName: eventName,
        userContext: context,
        eventProperties: eventProperties,
        accountId: _accountId,
        sdkKey: _sdkKey,
      );
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
  /// [attributes] The map of attributes to set.
  /// [context] The user context for the attribute.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of setting the attribute.
  Future<bool>? setAttribute(
      {required Map<String, dynamic> attributes,
      required VWOUserContext context}) async {
    try {
      final plugin = _fmePlugin;
      if (plugin == null) return false;

      return plugin.setAttribute(
        attributes: attributes,
        userContext: context,
        accountId: _accountId,
        sdkKey: _sdkKey,
      );
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

  /// Sets an alias for the current user in VWO.
  /// This method allows you to associate an alias ID with a user context for tracking purposes.
  ///
  /// The method calls the native platform implementation to set the alias and returns
  /// a boolean indicating success or failure.
  ///
  /// [context] The user context containing the temporary user ID.
  /// [alias] The original/authenticated user ID to link to the temporary ID.
  /// [accountId] Optional account ID for multi-instance support. If not provided, uses the instance's accountId.
  /// [sdkKey] Optional SDK key for multi-instance support. If not provided, uses the instance's sdkKey.
  ///
  /// Returns `true` if the alias was set successfully, `false` if there was an error
  /// or if the plugin is not available. Returns `null` if the method cannot be executed.
  Future<bool>? setAlias(
      {required VWOUserContext context, required String alias}) async {
    try {
      final plugin = _fmePlugin;
      if (plugin == null) return false;

      return plugin.setAlias(
        userContext: context,
        alias: alias,
        accountId: _accountId,
        sdkKey: _sdkKey,
      );
    } catch (e) {
      String details;
      if (e is PlatformException) {
        details = e.message ?? '';
      } else {
        details = e.toString();
      }
      logMessage('VWO: Failed to set alias $details');
      return false;
    }
  }

  /// Clears a specific VWO instance.
  ///
  /// [accountId] The account ID of the instance to clear.
  /// [sdkKey] The SDK key of the instance to clear.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of clearing the instance.
  static Future<bool> clearInstance({
    required int accountId,
    required String sdkKey,
  }) async {
    try {
      final plugin = VwoFmeFlutterSdkPlatform.instance;
      return await plugin.clearInstance(
        accountId: accountId,
        sdkKey: sdkKey,
      );
    } catch (e) {
      String details;
      if (e is PlatformException) {
        details = e.message ?? '';
      } else {
        details = e.toString();
      }
      logMessage('VWO: Failed to clear instance $details');
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
