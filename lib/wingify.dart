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

import 'package:flutter/services.dart';

import 'internal/fme_client.dart';
import 'wingify/models/wingify_init_options.dart';
import 'wingify/models/wingify_user_context.dart';

/// The main entry point for the Wingify FME Flutter SDK.
///
/// Provides initialization, feature-flag evaluation, event tracking, and
/// user attribute APIs.
class Wingify extends FmeClient {
  Wingify();

  /// Initializes the Wingify SDK.
  ///
  /// Returns a [Wingify] instance on success, or `null` if an error occurs.
  static Future<Wingify?> init(WingifyInitOptions options) async {
    final wingify = Wingify();
    try {
      await wingify.attach(options);
      return wingify;
    } catch (e) {
      logMessage(
          'Wingify: Error: ${e is PlatformException ? (e.message ?? '') : e}');
      return null;
    }
  }

  /// Gets an existing Wingify instance previously created via [init].
  static Wingify? getInstance(
      {required int accountId, required String sdkKey}) {
    final client = FmeClient.instances[FmeClient.instanceKey(accountId, sdkKey)];
    return client is Wingify ? client : null;
  }

  /// Links a temporary user ID to an authenticated user ID.
  ///
  /// Returns `false` if the SDK is not initialized or the call fails.
  /// Signature matches v1.9.0 ([Future<bool>?]).
  Future<bool>? setAlias({
    required WingifyUserContext context,
    required String alias,
  }) async {
    return invokeSetAlias(context: context, alias: alias);
  }

  /// Prints a message in debug mode only.
  static void logMessage(String message) => FmeClient.logMessage(message);
}
