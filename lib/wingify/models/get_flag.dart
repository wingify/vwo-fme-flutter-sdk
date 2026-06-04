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

import 'package:flutter/foundation.dart';

import 'variable.dart';

/// Represents a feature flag and its associated variables.
class GetFlag {
  bool _isEnabled;
  final List<Variable> variables;

  bool isEnabled() => _isEnabled;

  void setIsEnabled(bool value) {
    _isEnabled = value;
  }

  GetFlag({
    required bool isEnabled,
    required this.variables,
  }) : _isEnabled = isEnabled;

  factory GetFlag.fromMap(Map<String, dynamic> map) {
    final bool isEnabled = map['isEnabled'] is bool ? map['isEnabled'] : false;

    List<Variable> variables = [];
    if (map['variables'] is List) {
      variables = (map['variables'] as List<dynamic>).map((v) {
        if (v is Map<Object?, Object?>) {
          return Variable.fromMap(v.cast<String, dynamic>());
        }
        return Variable();
      }).toList();
    }

    return GetFlag(
      isEnabled: isEnabled,
      variables: variables,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': _isEnabled,
      'variables': variables.map((variable) => variable.toMap()).toList(),
    };
  }

  dynamic getVariable(String? key, dynamic defaultValue) {
    for (final variable in variables) {
      if (variable.key == key) {
        return variable.value ?? defaultValue;
      }
    }
    return defaultValue;
  }

  Map<String, dynamic>? getRecommendationDisplayConfig(String? key) {
    for (final variable in variables) {
      if (variable.key == key &&
          (variable.type?.toLowerCase() == 'recommendation')) {
        final config = variable.displayConfiguration;
        if (config is Map) {
          return Map<String, dynamic>.from(config);
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> getVariables() {
    final result = <Map<String, dynamic>>[];
    for (final variable in variables) {
      if (variable.type?.toLowerCase() != 'recommendation') {
        result.add(variable.toMap());
      }
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
