/*
 * Copyright (c) 2024-2025 Wingify Software Pvt. Ltd.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
import 'package:vwo_fme_flutter_sdk/utils/sdk_info.dart';

import '../vwo/models/vwo_init_options.dart';

class UsageStats {
  static const String _keyLanguageVersion = "lv";

  final VWOInitOptions initOptions;
  final Map<String, String> _stats = {};

  UsageStats(this.initOptions);

  Future<void> _collectStats() async {
    _stats[_keyLanguageVersion] = 'Dart ${SDKInfoUtils().getCleanDartVersion()}';
  }

  Future<Map<String, dynamic>> getStats() async{
    if (!initOptions.isUsageStatsDisabled) {
      await _collectStats();
      initOptions.vwo_meta.addAll(_stats);
      return initOptions.vwo_meta;
    }
    return Future.value({});
  }
}