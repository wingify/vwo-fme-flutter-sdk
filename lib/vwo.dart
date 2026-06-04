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
import 'vwo/models/vwo_init_options.dart';
import 'vwo/models/vwo_user_context.dart';

/// The legacy entry point for the VWO FME Flutter SDK.
///
/// Deprecated: use `Wingify` instead. The VWO API continues to work without
/// changes; see MIGRATE.md for the migration guide.
@Deprecated('Use Wingify instead. See MIGRATE.md.')
class VWO extends FmeClient {
  VWO();

  /// Initializes the VWO SDK.
  ///
  /// Returns a [VWO] instance on success, or `null` if an error occurs.
  static Future<VWO?> init(VWOInitOptions options) async {
    final vwo = VWO();
    try {
      await vwo.attach(options);
      return vwo;
    } catch (e) {
      logMessage('VWO: Error: ${e is PlatformException ? (e.message ?? '') : e}');
      return null;
    }
  }

  /// Gets an existing VWO instance previously created via [init].
  static VWO? getInstance({required int accountId, required String sdkKey}) {
    final client = FmeClient.instances[FmeClient.instanceKey(accountId, sdkKey)];
    return client is VWO ? client : null;
  }

  /// Links a temporary user ID to an authenticated user ID.
  ///
  /// Returns `false` if the SDK is not initialized or the call fails.
  /// Signature matches v1.9.0 ([Future<bool>?]).
  Future<bool>? setAlias({
    required VWOUserContext context,
    required String alias,
  }) async {
    return invokeSetAlias(context: context, alias: alias);
  }

  /// Prints a message in debug mode only.
  static void logMessage(String message) => FmeClient.logMessage(message);
}
