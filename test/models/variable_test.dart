import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/variable.dart';

void main() {
  group('Variable Tests', () {
    test('should create instance with all parameters', () {
      // Act
      final variable = Variable(
        value: 'test_value',
        type: 'string',
        key: 'test_key',
        id: 123,
        displayConfiguration: {'color': 'red'},
      );

      // Assert
      expect(variable.value, equals('test_value'));
      expect(variable.type, equals('string'));
      expect(variable.key, equals('test_key'));
      expect(variable.id, equals(123));
      expect(variable.displayConfiguration, equals({'color': 'red'}));
    });

    test('should create instance with null parameters', () {
      // Act
      final variable = Variable();

      // Assert
      expect(variable.value, isNull);
      expect(variable.type, isNull);
      expect(variable.key, isNull);
      expect(variable.id, isNull);
      expect(variable.displayConfiguration, isNull);
    });

    test('should create instance from map', () {
      // Arrange
      final map = {
        'value': 'test_value',
        'type': 'string',
        'key': 'test_key',
        'id': 123,
        'displayConfiguration': {'color': 'red'},
      };

      // Act
      final variable = Variable.fromMap(map);

      // Assert
      expect(variable.value, equals('test_value'));
      expect(variable.type, equals('string'));
      expect(variable.key, equals('test_key'));
      expect(variable.id, equals(123));
      expect(variable.displayConfiguration, equals({'color': 'red'}));
    });

    test('should create instance from map with missing values', () {
      // Arrange
      final map = {
        'value': 'test_value',
        'type': 'string',
        // Missing key, id, and displayConfiguration
      };

      // Act
      final variable = Variable.fromMap(map);

      // Assert
      expect(variable.value, equals('test_value'));
      expect(variable.type, equals('string'));
      expect(variable.key, isNull);
      expect(variable.id, isNull);
      expect(variable.displayConfiguration, isNull);
    });

    test('should create instance from empty map', () {
      // Act
      final variable = Variable.fromMap({});

      // Assert
      expect(variable.value, isNull);
      expect(variable.type, isNull);
      expect(variable.key, isNull);
      expect(variable.id, isNull);
      expect(variable.displayConfiguration, isNull);
    });

    test('should convert to map correctly', () {
      // Arrange
      final variable = Variable(
        value: 'test_value',
        type: 'string',
        key: 'test_key',
        id: 123,
        displayConfiguration: {'color': 'red'},
      );

      // Act
      final map = variable.toMap();

      // Assert
      expect(map['value'], equals('test_value'));
      expect(map['type'], equals('string'));
      expect(map['key'], equals('test_key'));
      expect(map['id'], equals(123));
      expect(map['displayConfiguration'], equals({'color': 'red'}));
    });

    test('should convert to map with null values', () {
      // Arrange
      final variable = Variable();

      // Act
      final map = variable.toMap();

      // Assert
      expect(map['value'], isNull);
      expect(map['type'], isNull);
      expect(map['key'], isNull);
      expect(map['id'], isNull);
      expect(map['displayConfiguration'], isNull);
    });

    test('should handle different value types', () {
      // Test with different value types
      final testCases = [
        {'value': 'string_value', 'type': 'string'},
        {'value': 42, 'type': 'number'},
        {'value': true, 'type': 'boolean'},
        {
          'value': {'nested': 'object'},
          'type': 'object'
        },
        {
          'value': [1, 2, 3],
          'type': 'array'
        },
      ];

      for (final testCase in testCases) {
        // Act
        final variable = Variable(
          value: testCase['value'],
          type: testCase['type'] as String,
          key: 'test_key',
          id: 1,
        );

        // Assert
        expect(variable.value, equals(testCase['value']));
        expect(variable.type, equals(testCase['type']));
      }
    });
  });
}
