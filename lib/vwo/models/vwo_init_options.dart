/// Copyright 2024-2026 Wingify Software Pvt. Ltd.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
/// http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

import '../../wingify/models/wingify_init_options.dart';

/// Deprecated: use [WingifyInitOptions] instead. See MIGRATE.md.
@Deprecated('Use WingifyInitOptions instead. See MIGRATE.md.')
class VWOInitOptions extends WingifyInitOptions {
  VWOInitOptions({
    required super.sdkKey,
    required super.accountId,
    super.logger,
    super.gatewayService,
    super.pollInterval,
    super.cachedSettingsExpiryTime,
    super.integrations,
    super.batchMinSize = -1,
    super.batchUploadTimeInterval = -1,
    super.isUsageStatsDisabled = false,
    super.isAliasingEnabled = false,
  });

  @override
  bool get useWingifyApi => false;

  /// Legacy name for [platformMeta]. Supports assignment and in-place mutation
  /// like the v1.9.0 `vwo_meta` field.
  @override
  Map<String, dynamic> get vwo_meta => platformMeta;

  @override
  set vwo_meta(Map<String, dynamic> value) => platformMeta = value;

  @override
  String toString() {
    return 'VWOInitOptions('
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
        'vwo_meta: $platformMeta)';
  }
}
