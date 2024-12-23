/*
 * Copyright 2024 Wingify Software Pvt. Ltd.
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

/// Represents a variable in VWO.
/// This class encapsulates information about a VWO variable, including its
/// value,type, key, and ID.
class Variable {
  dynamic value;
  String? type;
  String? key;
  int? id;
  dynamic displayConfiguration;

  Variable({
    this.value,
    this.type,
    this.key,
    this.id,
    this.displayConfiguration,
  });

  /// Create an instance from a map
  factory Variable.fromMap(Map<String, dynamic> map) {
    return Variable(
      value: map['value'],
      type: map['type'],
      key: map['key'],
      id: map['id'],
      displayConfiguration: map['displayConfiguration'],
    );
  }

  /// Convert to a Map to send to Kotlin
  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'type': type,
      'key': key,
      'id': id,
      'displayConfiguration': displayConfiguration,
    };
  }
}