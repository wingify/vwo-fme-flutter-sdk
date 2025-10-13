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
import 'dart:io';

class SDKInfoUtils {

  String getDartVersion() {
    // Returns something like '2.19.0 (stable) (Mon Jan 23 11:29:09 2023 -0800) on "android_arm64"'
    return Platform.version;
  }

  String getCleanDartVersion() {
    try {
      final fullVersion = getDartVersion();
      final versionMatch = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(fullVersion);
      return versionMatch?.group(1) ?? fullVersion;
    } catch (e) {
      return "";
    }
  }
}