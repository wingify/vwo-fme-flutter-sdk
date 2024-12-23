/// Copyright 2024 Wingify Software Pvt. Ltd.
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

import 'package:flutter/foundation.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/variable.dart';

/// Represents a feature flag and its associated variables.
/// This class encapsulates information about a feature flag, including its enabled status and a
/// list of variables with their values.
class GetFlag {
  bool _isEnabled;
  final List<Variable> variables;

  /// Returns whether the flag is enabled.
  bool isEnabled() {
    return _isEnabled;
  }

  /// Sets isEnabled.
  void setIsEnabled(bool value) {
    _isEnabled = value;
  }

  /// Constructor
  GetFlag({
    required bool isEnabled,
    required this.variables,
  }) : _isEnabled = isEnabled;

  /// Factory constructor to create a Flag from a Map
  factory GetFlag.fromMap(Map<String, dynamic> map) {
    // Safely cast '_isEnabled' to a boolean
    bool isEnabled = map['isEnabled'] is bool ? map['isEnabled'] : false;

    // Safely handle the 'variables' list, ensuring each item is a Map<String, dynamic>
    List<Variable> variables = [];
    if (map['variables'] is List) {
      variables = (map['variables'] as List<dynamic>).map((v) {
        if (v is Map<Object?, Object?>) {
          // Safely convert the map to Map<String, dynamic>
          Map<String, dynamic> map = v.cast<String, dynamic>();
          return Variable.fromMap(map);
        }
        return Variable(); // Or handle invalid case
      }).toList();
    }

    return GetFlag(
      isEnabled: isEnabled,
      variables: variables,
    );
  }

  /// Method to convert Flag object to a map
  Map<String, dynamic> toMap() {
    return {
      'isEnabled': _isEnabled,
      'variables': variables.map((variable) => variable.toMap()).toList(),
    };
  }

  /// Get a variable by key, returning a default value if not found
  dynamic getVariable(String? key, dynamic defaultValue) {
    for (var variable in variables) {
      if (variable.key == key) {
        return variable.value;
      }
    }
    return defaultValue;
  }

  /// Get a list of variables as a list of maps, excluding RECOMMENDATION type variables
  List<Map<String, dynamic>> getVariables() {
    List<Map<String, dynamic>> result = [];
    for (var variable in variables) {
        result.add(variable.toMap());
    }
    return result;
  }

  @override
  String toString() {
    return 'Flag(isEnabled: $_isEnabled, variables: $variables)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetFlag &&
        other._isEnabled == _isEnabled &&
        listEquals(other.variables, variables);
  }

  @override
  int get hashCode => _isEnabled.hashCode ^ variables.hashCode;
}
