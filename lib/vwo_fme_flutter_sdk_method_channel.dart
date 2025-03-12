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
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_context.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';

import 'logger/log_transport.dart';
import 'vwo_fme_flutter_sdk_platform_interface.dart';

/// An implementation of [VwoFmeFlutterSdkPlatform] that uses method channels.
class MethodChannelVwoFmeFlutterSdk extends VwoFmeFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  static const methodChannel = MethodChannel('vwo_fme_flutter_sdk');

  List<Map<String, dynamic>>? _transports;

  /// Initializes the VWO FME Flutter SDK.
  ///
  /// This method is the entry point for setting up and configuring the VWO FME
  /// Flutter SDK. It establishes communication with the native SDKs (Android/iOS)
  /// and prepares the SDK for use.
  ///
  /// This method should be called once during the application's startup.
  ///
  /// [options] The initialization options for the VWO FME SDK. This object
  ///           contains configuration details such as the account ID,
  ///           environment key, and other settings.
  ///
  /// Returns a [Future] that completes with an instance of
  /// [MethodChannelVwoFmeFlutterSdk] if the initialization is successful,
  /// or error if the initialization fails.
  static Future<MethodChannelVwoFmeFlutterSdk?> init(
      VWOInitOptions options) async {

    // Validate required parameters
    if (options.sdkKey.isEmpty) {
      return Future.error(
          ArgumentError('sdkKey is required and cannot be empty'));
    }
    if (options.accountId <= 0) {
      return Future.error(ArgumentError(
          'accountId is required and must be a positive integer'));
    }
    List<Map<String, dynamic>> transportsCopy =
        _prepareLoggersForBridge(options);

      final parameters = {
        'sdkKey': options.sdkKey,
        'accountId': options.accountId,
        'logger': options.logger,
        'gatewayService': options.gatewayService,
        'pollInterval': options.pollInterval,
        'cachedSettingsExpiryTime': options.cachedSettingsExpiryTime,
        'batchMinSize': options.batchMinSize,
        'batchUploadTimeInterval': "${options.batchUploadTimeInterval}",
      };

    var flutterSdk = MethodChannelVwoFmeFlutterSdk();
    // Set the integration callback handler if provided
    flutterSdk._setBridgeCallbackHandler(options);
    flutterSdk._transports = transportsCopy;

    await methodChannel.invokeMethod('init', parameters);
    return flutterSdk;
  }

  /// Prepares the loggers for the bridge by converting them to a list of maps.
  ///
  /// This method iterates through the transports in the logger configuration and
  /// creates a new list of maps, where each map represents a transport.
  ///
  /// The original `transports` list in the logger configuration is modified in place.
  /// Each `LogTransport` object is replaced with `true` in the original list.
  ///
  /// [options] The initialization options for the VWO SDK, which may contain
  ///           logger configuration with a list of transports.
  ///
  /// Returns a list of maps representing the loggers. Each map contains a single
  /// key-value pair, where the key is a string (the transport name) and the
  /// value is a [LogTransport] object.
  static List<Map<String, dynamic>> _prepareLoggersForBridge(
      VWOInitOptions options) {
    List<Map<String, dynamic>> transportsCopy = <Map<String, dynamic>>[];
    if (options.logger?.containsKey("transports") == true) {
      // Extract the transports list from the logger
      var transports =
          options.logger!["transports"] as List<Map<String, dynamic>>;

      // Iterate through the transports list
      for (var transportMap in transports) {
        var map = <String, LogTransport>{};
        transportMap.forEach((key, value) {
          if (transportMap[key] != null && transportMap[key] is LogTransport) {
            map[key] = value;
            transportMap[key] = true;
          } else if (transportMap[key] != null) {
            transportMap[key] = true;
          }
        });
        transportsCopy.add(map);
      }
    }
    return transportsCopy;
  }

  /// Handles the `onIntegrationCallback` method call from the native side.
  ///
  /// This function extracts the properties from the call arguments and
  /// calls the integration callback function if provided.
  ///
  /// [options] The initialization options for the VWO SDK.
  /// [properties] The properties map received from the native side.
  void _setBridgeCallbackHandler(VWOInitOptions options) {

    methodChannel.setMethodCallHandler((call) async {

      final Map<String, dynamic> properties =
          Map<String, dynamic>.from(call.arguments);

      if (call.method == "onIntegrationCallback") {

        options.integrationCallback?.call(properties);
      } else if (call.method == "onLoggerCallback") {

        _processLog(properties);
      }
    });
  }

  /// Processes a log message received from the native side.
  ///
  /// This method handles log messages received through the `onLoggerCallback`
  /// method call from the native platform. It iterates through the registered
  /// log transports (`_transports`) and forwards the log message to each of them.
  ///
  /// If `_transports` is null or empty, this method does nothing.
  ///
  /// [properties] A map containing the log message properties, including
  ///              "level" (the log level) and "message" (the log message).
  void _processLog(Map<String, dynamic> properties) {
    if (_transports == null || _transports?.isEmpty == true) return;
    // var transports = options.logger!["transports"] as List<Map<String, dynamic>>;
    var transport = _transports!;
    // Iterate through the transports list
    for (var transportMap in transport) {
      for (var element in transportMap.entries) {
        var logTransport = element.value as LogTransport;
        var level = properties["level"];
        var message = properties["message"];
        logTransport.log(level, message);
      }
    }
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
  /// [attributes] The map of the attributes.
  /// [context] The user context for the attribute.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of setting the attribute.
  @override
  Future<bool> setAttribute(
      {required Map<String, dynamic> attributes,
      required VWOContext userContext}) async {
    try {
      final Map<String, dynamic> arguments = {
        'attributes': attributes,
        'context': userContext.toMap(),
      };
      final result =
          await methodChannel.invokeMethod<bool>('setAttribute', arguments);
      return result ?? false;
    } on PlatformException catch (e) {
      // Handle errors from the native side
      throw Exception("Error: ${e.code}, ${e.message}");
    }
  }

  @override
  Future<bool> setSessionData(Map<String, dynamic> sessionData) async {
    try {
      return await methodChannel.invokeMethod('setSessionData', sessionData) ??
          false;
    } on PlatformException catch (e) {
      // Handle errors from the native side
      throw Exception("Error: ${e.code}, ${e.message}");
    }
  }
}
