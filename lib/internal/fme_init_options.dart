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

/// Shared initialization contract. `WingifyInitOptions` is the base
/// implementation; legacy `VWOInitOptions` extends it.
///
/// The only behavioral difference between the two brands is [useWingifyApi],
/// which the native bridge uses to route initialization through the Wingify
/// or VWO API. Everything else is identical wire data.
abstract class FmeInitOptions {
  String get sdkKey;
  int get accountId;
  Map<String, dynamic>? get logger;
  Map<String, String>? get gatewayService;
  int? get pollInterval;
  int? get cachedSettingsExpiryTime;
  Function(Map<String, dynamic>)? get integrations;
  int get batchMinSize;
  int get batchUploadTimeInterval;
  bool get isUsageStatsDisabled;
  bool? get isAliasingEnabled;

  /// Internal SDK metadata, sent to native as `_vwo_meta` for both brands.
  Map<String, dynamic> get platformMeta;

  /// Whether to initialize through the Wingify native API (`true`) or the
  /// legacy VWO native API (`false`).
  bool get useWingifyApi;
}
