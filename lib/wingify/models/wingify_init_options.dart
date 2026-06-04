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

import '../../internal/fme_init_options.dart';

/// Initialization options for the Wingify FME SDK.
class WingifyInitOptions implements FmeInitOptions {
  @override
  final String sdkKey;
  @override
  final int accountId;
  @override
  final Map<String, dynamic>? logger;
  @override
  final Map<String, String>? gatewayService;
  @override
  final int? pollInterval;
  @override
  final int? cachedSettingsExpiryTime;
  @override
  final Function(Map<String, dynamic>)? integrations;

  /// Optional: Minimum size of Batch to upload
  @override
  final int batchMinSize;

  /// Optional: Batch upload time interval in milliseconds. Please specify at least few minutes
  @override
  final int batchUploadTimeInterval;

  /// Optional: Usage stats should always be collected, don't collect if [isUsageStatsDisabled] flag is true
  @override
  bool isUsageStatsDisabled;

  /// Optional: if aliasing is enabled
  @override
  bool? isAliasingEnabled;

  /// Internal SDK metadata.
  @override
  Map<String, dynamic> platformMeta = {};

  /// Legacy name for [platformMeta]. Supports assignment and in-place mutation
  /// like the v1.9.0 `vwo_meta` field.
  Map<String, dynamic> get vwo_meta => platformMeta;

  set vwo_meta(Map<String, dynamic> value) => platformMeta = value;

  @override
  bool get useWingifyApi => true;

  WingifyInitOptions({
    required this.sdkKey,
    required this.accountId,
    this.logger,
    this.gatewayService,
    this.pollInterval,
    this.cachedSettingsExpiryTime,
    this.integrations,
    this.batchMinSize = -1,
    this.batchUploadTimeInterval = -1,
    this.isUsageStatsDisabled = false,
    this.isAliasingEnabled = false,
  });

  @override
  String toString() {
    return 'WingifyInitOptions('
        'sdkKey: $sdkKey, '
        'accountId: $accountId, '
        'logger: $logger, '
        'gatewayService: $gatewayService, '
        'pollInterval: $pollInterval, '
        'cachedSettingsExpiryTime: $cachedSettingsExpiryTime, '
        'integrationCallback: ${integrations != null ? 'Provided' : 'Not Provided'}, '
        'batchMinSize: $batchMinSize, '
        'batchUploadTimeInterval: $batchUploadTimeInterval, '
        'isUsageStatsDisabled: $isUsageStatsDisabled, '
        'isAliasingEnabled: $isAliasingEnabled, '
        'platformMeta: $platformMeta)';
  }
}
