import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/logger/log_transport.dart';

// Test implementation of LogTransport
class TestLogTransport implements LogTransport {
  final List<Map<String, String>> logs = [];

  @override
  void log(String level, String message) {
    logs.add({'level': level, 'message': message});
  }

  void clear() {
    logs.clear();
  }
}

// Another test implementation that throws exceptions
class FaultyLogTransport implements LogTransport {
  @override
  void log(String level, String message) {
    throw Exception('Logging failed');
  }
}

void main() {
  group('LogTransport Tests', () {
    late TestLogTransport testLogger;

    setUp(() {
      testLogger = TestLogTransport();
    });

    test('should log messages with correct level and content', () {
      // Act
      testLogger.log('INFO', 'Test info message');
      testLogger.log('ERROR', 'Test error message');
      testLogger.log('DEBUG', 'Test debug message');

      // Assert
      expect(testLogger.logs.length, equals(3));
      expect(testLogger.logs[0]['level'], equals('INFO'));
      expect(testLogger.logs[0]['message'], equals('Test info message'));
      expect(testLogger.logs[1]['level'], equals('ERROR'));
      expect(testLogger.logs[1]['message'], equals('Test error message'));
      expect(testLogger.logs[2]['level'], equals('DEBUG'));
      expect(testLogger.logs[2]['message'], equals('Test debug message'));
    });

    test('should handle empty messages', () {
      // Act
      testLogger.log('INFO', '');

      // Assert
      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs[0]['level'], equals('INFO'));
      expect(testLogger.logs[0]['message'], equals(''));
    });

    test('should handle different log levels', () {
      // Arrange
      final levels = ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR'];

      // Act
      for (final level in levels) {
        testLogger.log(level, 'Message for $level');
      }

      // Assert
      expect(testLogger.logs.length, equals(5));
      for (int i = 0; i < levels.length; i++) {
        expect(testLogger.logs[i]['level'], equals(levels[i]));
        expect(
            testLogger.logs[i]['message'], equals('Message for ${levels[i]}'));
      }
    });

    test('should handle long messages', () {
      // Arrange
      final longMessage = 'a' * 1000; // 1000 character message

      // Act
      testLogger.log('INFO', longMessage);

      // Assert
      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs[0]['level'], equals('INFO'));
      expect(testLogger.logs[0]['message'], equals(longMessage));
      expect(testLogger.logs[0]['message']!.length, equals(1000));
    });

    test('should handle special characters in messages', () {
      // Arrange
      final specialMessage =
          'Message with special chars: !@#\$%^&*()[]{}|;:"<>?,./\\n\\t';

      // Act
      testLogger.log('INFO', specialMessage);

      // Assert
      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs[0]['level'], equals('INFO'));
      expect(testLogger.logs[0]['message'], equals(specialMessage));
    });

    test('should handle unicode characters', () {
      // Arrange
      final unicodeMessage = 'Unicode: 🚀 🌟 ✨ 中文 العربية';

      // Act
      testLogger.log('INFO', unicodeMessage);

      // Assert
      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs[0]['level'], equals('INFO'));
      expect(testLogger.logs[0]['message'], equals(unicodeMessage));
    });

    test('should be able to clear logs', () {
      // Arrange
      testLogger.log('INFO', 'Test message 1');
      testLogger.log('ERROR', 'Test message 2');
      expect(testLogger.logs.length, equals(2));

      // Act
      testLogger.clear();

      // Assert
      expect(testLogger.logs.length, equals(0));
    });

    test('should handle multiple implementations', () {
      // Arrange
      final logger1 = TestLogTransport();
      final logger2 = TestLogTransport();

      // Act
      logger1.log('INFO', 'Message to logger 1');
      logger2.log('ERROR', 'Message to logger 2');

      // Assert
      expect(logger1.logs.length, equals(1));
      expect(logger2.logs.length, equals(1));
      expect(logger1.logs[0]['message'], equals('Message to logger 1'));
      expect(logger2.logs[0]['message'], equals('Message to logger 2'));
    });

    test('should handle faulty logger implementation', () {
      // Arrange
      final faultyLogger = FaultyLogTransport();

      // Act & Assert
      expect(() => faultyLogger.log('INFO', 'Test message'), throwsException);
    });

    test('should maintain order of log messages', () {
      // Act
      for (int i = 0; i < 10; i++) {
        testLogger.log('INFO', 'Message $i');
      }

      // Assert
      expect(testLogger.logs.length, equals(10));
      for (int i = 0; i < 10; i++) {
        expect(testLogger.logs[i]['message'], equals('Message $i'));
      }
    });
  });
}
