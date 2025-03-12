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


/// An interface for logging transports.
///
/// A logging transport is a mechanism for sending log messages to a destination,
/// such as the Flutter console or a remote server.
abstract class LogTransport {

  /// Logs a message with the given level.
  ///
  /// This method is called to log a message to the Flutter console.
  ///
  /// [level] The log level (e.g., "DEBUG", "INFO", "ERROR").
  /// [message] The message to log.
  void log(String level, String message);
}