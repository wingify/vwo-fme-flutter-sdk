/*
 * Copyright 2024-2026 Wingify Software Pvt. Ltd.
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

import '../wingify/models/get_flag.dart';
import '../vwo_fme_flutter_sdk_method_channel.dart';
import '../vwo_fme_flutter_sdk_platform_interface.dart';
import 'fme_init_options.dart';
import 'fme_user_context.dart';

/// Shared implementation behind the public `VWO` and `Wingify` facades.
///
/// Holds the initialized instance state and the SDK operations. The two
/// facades subclass this and only differ in their static entry points and the
/// init options they accept.
class FmeClient {
  VwoFmeFlutterSdkPlatform? fmePlugin;
  int? accountId;
  String? sdkKey;

  /// Cache of initialized clients keyed by "accountId_sdkKey".
  static final Map<String, FmeClient> instances = {};

  static String instanceKey(int accountId, String sdkKey) =>
      '${accountId}_$sdkKey';

  /// Initializes the native SDK for [options] and registers this client.
  Future<void> attach(FmeInitOptions options) async {
    fmePlugin = await MethodChannelVwoFmeFlutterSdk.init(options);
    accountId = options.accountId;
    sdkKey = options.sdkKey;
    instances[instanceKey(options.accountId, options.sdkKey)] = this;
  }

  /// Gets the value of a feature flag.
  Future<GetFlag?> getFlag({
    required String featureKey,
    required FmeUserContext context,
  }) {
    return fmePlugin?.getFlag(featureKey: featureKey, userContext: context) ??
        Future.value(null);
  }

  /// Tracks an event.
  Future<Map<String, bool>?> trackEvent({
    required String eventName,
    required FmeUserContext context,
    Map<String, dynamic>? eventProperties,
  }) {
    return fmePlugin?.trackEvent(
          eventName: eventName,
          userContext: context,
          eventProperties: eventProperties,
        ) ??
        Future.value(null);
  }

  /// Sets user attributes. Returns `false` if the SDK is not initialized.
  Future<bool> setAttribute({
    required Map<String, dynamic> attributes,
    required FmeUserContext context,
  }) async {
    final plugin = fmePlugin;
    if (plugin == null) return false;
    return plugin.setAttribute(attributes: attributes, userContext: context);
  }

  /// Shared [setAlias] implementation for [VWO] and [Wingify].
  Future<bool> invokeSetAlias({
    required FmeUserContext context,
    required String alias,
  }) async {
    try {
      final plugin = fmePlugin;
      if (plugin == null) return false;

      return await plugin.setAlias(userContext: context, alias: alias);
    } catch (e) {
      final details = e is PlatformException
          ? (e.message ?? '')
          : e.toString();
      logMessage('$runtimeType: Failed to set alias $details');
      return false;
    }
  }

  /// Clears this client instance.
  Future<bool> clearInstance() async {
    final result = await fmePlugin?.clearInstance() ?? false;
    if (result && accountId != null && sdkKey != null) {
      instances.remove(instanceKey(accountId!, sdkKey!));
    }
    return result;
  }

  /// Prints a message in debug mode only.
  static void logMessage(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }
}
