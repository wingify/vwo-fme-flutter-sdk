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

import 'package:vwo_fme_flutter_sdk/logger/log_transport.dart';

/// A log transport that uses Flutter's built-in `print` function for logging.
///
/// This class implements the [LogTransport] interface and provides a way to
/// log messages to the Flutter console. It formats the log messages with a
/// prefix "FME-Flutter:" and includes the log level.
class DartLogger implements LogTransport {

  @override
  void log(String level, String? message) {
    if (message == null) return;

    print("FME-Flutter: [$level] $message");
  }

  /// Converts this [DartLogger] instance to a map representation.
  ///
  /// This method is used to represent the [DartLogger] instance as a map,
  /// which is useful for serialization or passing the instance to native code.
  ///
  Map<String, dynamic> toMap() {
    return {
      "defaultTransport": this,
    };
  }
}