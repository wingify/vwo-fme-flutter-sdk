import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/variable.dart';

void main() {
  group('GetFlag Tests', () {
    test('should create instance with enabled flag and variables', () {
      // Arrange
      final variables = [
        Variable(key: 'color', value: 'blue', type: 'string', id: 1),
        Variable(key: 'size', value: 'large', type: 'string', id: 2),
      ];

      // Act
      final flag = GetFlag(isEnabled: true, variables: variables);

      // Assert
      expect(flag.isEnabled(), isTrue);
      expect(flag.variables.length, equals(2));
      expect(flag.variables[0].key, equals('color'));
      expect(flag.variables[1].key, equals('size'));
    });

    test('should create instance with disabled flag and empty variables', () {
      // Act
      final flag = GetFlag(isEnabled: false, variables: []);

      // Assert
      expect(flag.isEnabled(), isFalse);
      expect(flag.variables, isEmpty);
    });

    test('should allow setting isEnabled', () {
      // Arrange
      final flag = GetFlag(isEnabled: false, variables: []);

      // Act
      flag.setIsEnabled(true);

      // Assert
      expect(flag.isEnabled(), isTrue);
    });

    test('should create instance from map with valid data', () {
      // Arrange
      final map = {
        'isEnabled': true,
        'variables': [
          {
            'key': 'color',
            'value': 'blue',
            'type': 'string',
            'id': 1,
          },
          {
            'key': 'size',
            'value': 'large',
            'type': 'string',
            'id': 2,
          },
        ]
      };

      // Act
      final flag = GetFlag.fromMap(map);

      // Assert
      expect(flag.isEnabled(), isTrue);
      expect(flag.variables.length, equals(2));
      expect(flag.variables[0].key, equals('color'));
      expect(flag.variables[0].value, equals('blue'));
      expect(flag.variables[1].key, equals('size'));
      expect(flag.variables[1].value, equals('large'));
    });

    test('should create instance from map with isEnabled as non-boolean', () {
      // Arrange
      final map = {
        'isEnabled': 'true', // String instead of boolean
        'variables': []
      };

      // Act
      final flag = GetFlag.fromMap(map);

      // Assert
      expect(flag.isEnabled(), isFalse); // Should default to false
      expect(flag.variables, isEmpty);
    });

    test('should create instance from map with invalid variables', () {
      // Arrange
      final map = {
        'isEnabled': true,
        'variables': 'invalid' // Should be a list
      };

      // Act
      final flag = GetFlag.fromMap(map);

      // Assert
      expect(flag.isEnabled(), isTrue);
      expect(flag.variables, isEmpty);
    });

    test('should create instance from map with empty variables list', () {
      // Arrange
      final map = {'isEnabled': true, 'variables': []};

      // Act
      final flag = GetFlag.fromMap(map);

      // Assert
      expect(flag.isEnabled(), isTrue);
      expect(flag.variables, isEmpty);
    });

    test('should convert to map correctly', () {
      // Arrange
      final variables = [
        Variable(key: 'color', value: 'blue', type: 'string', id: 1),
        Variable(key: 'size', value: 'large', type: 'string', id: 2),
      ];
      final flag = GetFlag(isEnabled: true, variables: variables);

      // Act
      final map = flag.toMap();

      // Assert
      expect(map['isEnabled'], isTrue);
      expect(map['variables'], isA<List>());
      expect((map['variables'] as List).length, equals(2));
      expect((map['variables'] as List)[0]['key'], equals('color'));
      expect((map['variables'] as List)[1]['key'], equals('size'));
    });

    test('should get variable by key', () {
      // Arrange
      final variables = [
        Variable(key: 'color', value: 'blue', type: 'string', id: 1),
        Variable(key: 'size', value: 'large', type: 'string', id: 2),
      ];
      final flag = GetFlag(isEnabled: true, variables: variables);

      // Act & Assert
      expect(flag.getVariable('color', 'default'), equals('blue'));
      expect(flag.getVariable('size', 'default'), equals('large'));
      expect(flag.getVariable('nonexistent', 'default'), equals('default'));
    });

    test('should get variable by null key', () {
      // Arrange
      final variables = [
        Variable(key: null, value: 'nullKeyValue', type: 'string', id: 1),
        Variable(key: 'size', value: 'large', type: 'string', id: 2),
      ];
      final flag = GetFlag(isEnabled: true, variables: variables);

      // Act & Assert
      expect(flag.getVariable(null, 'default'), equals('nullKeyValue'));
    });

    test('should get variables as list of maps', () {
      // Arrange
      final variables = [
        Variable(key: 'color', value: 'blue', type: 'string', id: 1),
        Variable(key: 'size', value: 'large', type: 'string', id: 2),
      ];
      final flag = GetFlag(isEnabled: true, variables: variables);

      // Act
      final variablesList = flag.getVariables();

      // Assert
      expect(variablesList.length, equals(2));
      expect(variablesList[0]['key'], equals('color'));
      expect(variablesList[0]['value'], equals('blue'));
      expect(variablesList[1]['key'], equals('size'));
      expect(variablesList[1]['value'], equals('large'));
    });

    test('should generate correct toString representation', () {
      // Arrange
      final variables = [
        Variable(key: 'color', value: 'blue', type: 'string', id: 1),
      ];
      final flag = GetFlag(isEnabled: true, variables: variables);

      // Act
      final result = flag.toString();

      // Assert
      expect(result, contains('Flag(isEnabled: true'));
      expect(result, contains('variables:'));
    });

    test('should implement equality correctly', () {
      // Arrange
      final sharedVariable =
          Variable(key: 'color', value: 'blue', type: 'string', id: 1);
      final variables1 = [sharedVariable];
      final variables2 = [sharedVariable]; // Same instance
      final flag1 = GetFlag(isEnabled: true, variables: variables1);
      final flag2 = GetFlag(isEnabled: true, variables: variables2);
      final flag3 = GetFlag(isEnabled: false, variables: variables1);

      // Act & Assert
      expect(flag1 == flag2, isTrue);
      expect(flag1 == flag3, isFalse);
      expect(flag1 == flag1, isTrue); // Same instance
    });

    test('should implement hashCode correctly', () {
      // Arrange
      final variables = [
        Variable(key: 'color', value: 'blue', type: 'string', id: 1),
      ];
      final flag1 = GetFlag(isEnabled: true, variables: variables);
      final flag2 = GetFlag(isEnabled: true, variables: variables);

      // Act & Assert
      expect(flag1.hashCode, equals(flag2.hashCode));
    });
  });
}
