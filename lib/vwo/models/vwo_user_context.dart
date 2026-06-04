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

import '../../wingify/models/wingify_user_context.dart';

/// Deprecated: use [WingifyUserContext] instead. See MIGRATE.md.
@Deprecated('Use WingifyUserContext instead. See MIGRATE.md.')
class VWOUserContext extends WingifyUserContext {
  VWOUserContext({
    super.id,
    super.customVariables,
    super.shouldUseDeviceIdAsUserId = false,
  });

  @override
  String toString() {
    return 'VWOUserContext('
        'userId: $id, '
        'customVariables: $customVariables, '
        'shouldUseDeviceIdAsUserId: $shouldUseDeviceIdAsUserId)';
  }
}
