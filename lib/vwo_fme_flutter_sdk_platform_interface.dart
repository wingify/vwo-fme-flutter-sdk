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
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';

import 'vwo/models/vwo_user_context.dart';
import 'vwo_fme_flutter_sdk_method_channel.dart';

abstract class VwoFmeFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a VwoFmeFlutterSdkPlatform.
  VwoFmeFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static VwoFmeFlutterSdkPlatform _instance = MethodChannelVwoFmeFlutterSdk();

  /// The default instance of [VwoFmeFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelVwoFmeFlutterSdk].
  static VwoFmeFlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VwoFmeFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(VwoFmeFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets the value of a feature flag.
  ///
  /// [featureKey] The name of the feature flag.
  /// [userContext] The user context for evaluating the flag.
  /// [accountId] Optional account ID for multi-instance support.
  /// [sdkKey] Optional SDK key for multi-instance support.
  ///
  /// Returns a [Future] that resolves to a [GetFlag] object containing the flag value and other metadata.
  Future<GetFlag?> getFlag({
    required String featureKey,
    required VWOUserContext userContext,
    int? accountId,
    String? sdkKey,
  }) {
    throw UnimplementedError('getFlag() has not been implemented.');
  }

  /// Tracks an event.
  ///
  /// [eventName] The name of the event.
  /// [userContext] The user context for the event.
  /// [eventProperties] Optional properties associated with the event.
  /// [accountId] Optional account ID for multi-instance support.
  /// [sdkKey] Optional SDK key for multi-instance support.
  ///
  /// Returns a [Future] that resolves to a map indicating the success status of the event tracking.
  Future<Map<String, bool>> trackEvent({
    required String eventName,
    required VWOUserContext userContext,
    Map<String, dynamic>? eventProperties,
    int? accountId,
    String? sdkKey,
  }) {
    throw UnimplementedError('trackEvent() has not been implemented.');
  }

  /// Sets a user attribute.
  ///
  /// [attributes] The map of the attributes.
  /// [userContext] The user context for the attribute.
  /// [accountId] Optional account ID for multi-instance support.
  /// [sdkKey] Optional SDK key for multi-instance support.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of setting the attribute.
  Future<bool> setAttribute({
    required Map<String, dynamic> attributes,
    required VWOUserContext userContext,
    int? accountId,
    String? sdkKey,
  }) {
    throw UnimplementedError('setAttribute() has not been implemented.');
  }

  /// Sets an alias for a user (links temporary user ID to original user ID).
  ///
  /// [userContext] The user context containing the temporary user ID.
  /// [alias] The original/authenticated user ID to link to the temporary ID.
  /// [accountId] Optional account ID for multi-instance support.
  /// [sdkKey] Optional SDK key for multi-instance support.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of setting the alias.
  Future<bool> setAlias({
    required VWOUserContext userContext,
    required String alias,
    int? accountId,
    String? sdkKey,
  }) {
    throw UnimplementedError('setAlias() has not been implemented.');
  }

  /// Clears a specific VWO instance.
  ///
  /// [accountId] The account ID of the instance to clear.
  /// [sdkKey] The SDK key of the instance to clear.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of clearing the instance.
  Future<bool> clearInstance({
    required int accountId,
    required String sdkKey,
  }) {
    throw UnimplementedError('clearInstance() has not been implemented.');
  }

  Future<bool> setSessionData(Map<String, dynamic> sessionData) {
    throw UnimplementedError('setSessionData() has not been implemented.');
  }

  /// Sends SDK initialization event with timing information.
  ///
  /// [sdkInitTime] The time taken for SDK initialization in milliseconds.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of sending the event.
  Future<bool> sendSdkInitEvent(int sdkInitTime) {
    throw UnimplementedError('sendSdkInitEvent() has not been implemented.');
  }
}
