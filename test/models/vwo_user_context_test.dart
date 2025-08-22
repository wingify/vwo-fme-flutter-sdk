import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_user_context.dart';

void main() {
  group('VWOUserContext Tests', () {
    test('should create instance with required id parameter', () {
      // Act
      final userContext = VWOUserContext(id: 'user123');

      // Assert
      expect(userContext.id, equals('user123'));
      expect(userContext.customVariables, isNull);
    });

    test('should create instance with id and custom variables', () {
      // Arrange
      final customVariables = {
        'plan': 'premium',
        'age': 25,
        'isActive': true,
      };

      // Act
      final userContext = VWOUserContext(
        id: 'user123',
        customVariables: customVariables,
      );

      // Assert
      expect(userContext.id, equals('user123'));
      expect(userContext.customVariables, equals(customVariables));
    });

    test('should convert to map correctly', () {
      // Arrange
      final customVariables = {
        'plan': 'premium',
        'age': 25,
        'isActive': true,
      };
      final userContext = VWOUserContext(
        id: 'user123',
        customVariables: customVariables,
      );

      // Act
      final map = userContext.toMap();

      // Assert
      expect(map['id'], equals('user123'));
      expect(map['customVariables'], equals(customVariables));
    });

    test('should convert to map with null custom variables', () {
      // Arrange
      final userContext = VWOUserContext(id: 'user123');

      // Act
      final map = userContext.toMap();

      // Assert
      expect(map['id'], equals('user123'));
      expect(map['customVariables'], isNull);
    });

    test('should generate correct toString representation', () {
      // Arrange
      final customVariables = {
        'plan': 'premium',
        'age': 25,
      };
      final userContext = VWOUserContext(
        id: 'user123',
        customVariables: customVariables,
      );

      // Act
      final result = userContext.toString();

      // Assert
      expect(result, contains('VWOUserContext('));
      expect(result, contains('userId: user123'));
      expect(result, contains('customVariables: {plan: premium, age: 25}'));
    });

    test('should generate toString with null custom variables', () {
      // Arrange
      final userContext = VWOUserContext(id: 'user123');

      // Act
      final result = userContext.toString();

      // Assert
      expect(result, contains('VWOUserContext('));
      expect(result, contains('userId: user123'));
      expect(result, contains('customVariables: null'));
    });
  });
}
