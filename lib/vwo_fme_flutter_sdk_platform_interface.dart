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
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_context.dart';

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
  /// [flagName] The name of the feature flag.
  /// [vwoContext] The user context for evaluating the flag.
  ///
  /// Returns a [Future] that resolves to a [GetFlag] object containing the flag value and other metadata.
  Future<GetFlag?> getFlag({
    required String flagName,
    required VWOContext vwoContext,
  }) {
    throw UnimplementedError('getFlag() has not been implemented.');
  }

  /// Tracks an event.
  ///
  /// [eventName] The name of the event.
  /// [context] The user context for the event.
  /// [eventProperties] Optional properties associated with the event.
  ///
  /// Returns a [Future] that resolves to a map indicating the success status of the event tracking.
  Future<Map<String, bool>> trackEvent({
    required String eventName,
    required VWOContext vwoContext,
    Map<String, dynamic>? eventProperties,
  }) {
    throw UnimplementedError('trackEvent() has not been implemented.');
  }

  /// Sets a user attribute.
  ///
  /// [attributeKey] The key of the attribute.
  /// [attributeValue] The value of the attribute.
  /// [context] The user context for the attribute.
  ///
  /// Returns a [Future] that resolves to a boolean indicating the success status of setting the attribute.
  Future<bool> setAttribute({
    required String attributeKey,
    required dynamic attributeValue,
    required VWOContext vwoContext,
  }) {
    throw UnimplementedError('setAttribute() has not been implemented.');
  }
}
