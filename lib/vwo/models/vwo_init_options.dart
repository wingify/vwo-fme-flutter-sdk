/// Copyright 2024-2025 Wingify Software Pvt. Ltd.
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

class VWOInitOptions {
  final String sdkKey;
  final int accountId;
  final Map<String, dynamic>? logger;
  final Map<String, String>? gatewayService;
  final int? pollInterval;
  final int? cachedSettingsExpiryTime;
  final Function(Map<String, dynamic>)? integrationCallback;

  /// Optional: Minimum size of Batch to upload
  final int batchMinSize;

  /// Optional: Batch upload time interval in milliseconds. Please specify at least few minutes
  final int batchUploadTimeInterval;

  VWOInitOptions({
    required this.sdkKey,
    required this.accountId,
    this.logger,
    this.gatewayService,
    this.pollInterval,
    this.cachedSettingsExpiryTime,
    this.integrationCallback,
    this.batchMinSize = -1,
    this.batchUploadTimeInterval = -1,
  });

  @override
  String toString() {
    return 'VWOInitOptions('
        'sdkKey: $sdkKey, '
        'accountId: $accountId, '
        'logger: $logger, '
        'gatewayService: $gatewayService, '
        'pollInterval: $pollInterval, '
        'cachedSettingsExpiryTime: $cachedSettingsExpiryTime, '
        'integrationCallback: ${integrationCallback != null ? 'Provided' : 'Not Provided'}, '
        'batchMinSize: $batchMinSize, '
        'batchUploadTimeInterval: $batchUploadTimeInterval)';
  }
}