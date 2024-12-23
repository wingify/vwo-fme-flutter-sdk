/*
 * Copyright 2024 Wingify Software Pvt. Ltd.
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
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_context.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';

import 'vwo_fme_flutter_sdk_platform_interface.dart';

/// An implementation of [VwoFmeFlutterSdkPlatform] that uses method channels.
class MethodChannelVwoFmeFlutterSdk extends VwoFmeFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  static const methodChannel = MethodChannel('vwo_fme_flutter_sdk');

  /// Initializes the VWO SDK.
  ///
  /// This method should be called before any other VWO methods.
  ///
  /// [sdkKey] The SDK key for your VWO account.
  /// [accountId] The account ID for your VWO account.
  /// [logger] Optional logger configuration.
  /// [gatewayService] Optional gateway service configuration.
  /// [pollInterval] Optional poll interval for settings updates (in milliseconds).
  /// [cachedSettingsExpiryTime] Optional expiry time for cached settings (in milliseconds).
  ///
  /// Returns a [Future] that resolves to a string indicating the initialization status.
  static Future<MethodChannelVwoFmeFlutterSdk?> init(VWOInitOptions options) async {

      // Validate required parameters
      if (options.sdkKey.isEmpty) {
        return Future.error(
            ArgumentError('sdkKey is required and cannot be empty'));
      }
      if (options.accountId <= 0) {
        return Future.error(ArgumentError(
            'accountId is required and must be a positive integer'));
      }

      final parameters = {
        'sdkKey': options.sdkKey,
        'accountId': options.accountId,
        'logger': options.logger,
        'gatewayService': options.gatewayService,
        'pollInterval': options.pollInterval,
        'cachedSettingsExpiryTime': options.cachedSettingsExpiryTime,
      };

      await methodChannel.invokeMethod('init', parameters);
      var flutterSdk = MethodChannelVwoFmeFlutterSdk();
      // Set the integration callback handler if provided
      if (options.integrationCallback != null) {
        flutterSdk._setIntegrationCallbackHandler(options.integrationCallback!);
      }
      return flutterSdk;

}

  /// Sets the integration callback handler.
  ///
  /// [callback] The callback function to be invoked when an integration event occurs.
  /// The callback function receives a map containing the event data.
  void _setIntegrationCallbackHandler(Function(Map<String, dynamic>) callback) {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == "onIntegrationCallback") {
        final Map<String, dynamic> properties = Map<String, dynamic>.from(call.arguments);
        callback(properties);
      }
    });
  }

  /// Gets the value of a feature flag.
  ///
  /// [flagName] The name of the feature flag.
  /// [vwoContext] The user context for evaluating the flag.
  ///
  /// Returns a [Future] that resolves to a [GetFlag] object containing the flag value and other metadata.
  @override
  Future<GetFlag> getFlag({
    required String flagName,
    required VWOContext vwoContext,
  }) async {
    try {
      final dynamic result = await methodChannel.invokeMethod('getFlag', {
        'flagName': flagName,
        'userContext': vwoContext.toMap(),
      });

      // Explicitly cast the result to Map<String, dynamic> if possible
      if (result is Map) {
        // We need to cast every entry in the map to ensure the correct types
        final Map<String, dynamic> resultMap = {};
        result.forEach((key, value) {
          if (key is String) {
            resultMap[key] = value;  // Ensure value is dynamic
          }
        });
        return GetFlag.fromMap(resultMap);
      } else {
        throw Exception("Expected result type Map<String, dynamic> but got ${result.runtimeType}");
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  /// Tracks an event.
  ///
  /// [eventName] The name of the event.
  /// [context] The user context for the event.
  /// [eventProperties] Optional properties associated with the event.
  ///
  /// Returns a [Future] that resolves to a map indicating the success status of the event tracking.
  @override
  Future<Map<String, bool>> trackEvent({
    required String eventName,
    required VWOContext vwoContext,
    Map<String, dynamic>? eventProperties,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'trackEvent',
        {
          'eventName': eventName,
          'context': vwoContext.toMap(),
          'eventProperties': eventProperties,
        },
      );
      if (result == null) {
        throw Exception("No data returned from native code.");
      }
      // Convert dynamic map to typed Map<String, bool>
      return Map<String, bool>.from(result);
    } on PlatformException catch (e) {
      // Handle errors from the native side
      throw Exception("Error: ${e.code}, ${e.message}");
    }
  }

  /// Sets a user attribute.
  ///
  /// [attributeKey] The key of the attribute.
  /// [attributeValue] The value of the attribute.
  /// [context] The user context for the attribute.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of setting the attribute.
  @override
  Future<bool> setAttribute({
    required String attributeKey,
    required dynamic attributeValue,
    required VWOContext vwoContext,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'setAttribute',
        {
          'attributeKey': attributeKey,
          'attributeValue': attributeValue,
          'context': vwoContext.toMap(),
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      // Handle errors from the native side
      throw Exception("Error: ${e.code}, ${e.message}");
    }
  }
}
