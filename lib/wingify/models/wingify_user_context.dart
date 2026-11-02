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

import '../../internal/fme_user_context.dart';

/// Identifies a user for feature-flag evaluation, tracking, and targeting.
class WingifyUserContext implements FmeUserContext {
  final String? id;
  final Map<String, dynamic>? customVariables;
  final bool shouldUseDeviceIdAsUserId;

  /// Bucketing key. When this is set, native ignores [id] for variation assignment.
  /// Null or empty falls back to [id]. A shared seed puts different users on the same variation.
  final String? bucketingSeed;

  /// Names of entries in [customVariables] that are applied after the variation is chosen.
  final List<String>? postSegmentationVariables;

  /// User IP for gateway user-details. Only used when a gateway was set at init, and only on iOS.
  final String? ipAddress;

  WingifyUserContext({
    this.id,
    this.customVariables,
    this.shouldUseDeviceIdAsUserId = false,
    this.bucketingSeed,
    this.postSegmentationVariables,
    this.ipAddress,
  });

  /// Converts the `WingifyUserContext` object into a Map.
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customVariables': customVariables,
      'shouldUseDeviceIdAsUserId': shouldUseDeviceIdAsUserId,
      'bucketingSeed': bucketingSeed,
      'postSegmentationVariables': postSegmentationVariables,
      'ipAddress': ipAddress,
    };
  }

  @override
  String toString() {
    return 'WingifyUserContext('
        'userId: $id, '
        'customVariables: $customVariables, '
        'shouldUseDeviceIdAsUserId: $shouldUseDeviceIdAsUserId, '
        'bucketingSeed: $bucketingSeed, '
        'postSegmentationVariables: $postSegmentationVariables, '
        'ipAddress: $ipAddress)';
  }
}
