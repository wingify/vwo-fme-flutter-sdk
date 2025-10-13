import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/fme_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FmeConfig Tests', () {
    const MethodChannel methodChannel = MethodChannel('vwo_fme_flutter_sdk');
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel,
              (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    group('setSessionData()', () {
      test('should call native method with session data and return true',
          () async {
        // Arrange
        final sessionData = {'sessionId': 123456789};

        // Act
        final result = await FmeConfig.setSessionData(sessionData);

        // Assert
        expect(result, isTrue);
        expect(log.length, equals(1));
        expect(log[0].method, equals('setSessionData'));
        expect(log[0].arguments, equals(sessionData));
      });

      test('should handle empty session data', () async {
        // Arrange
        final sessionData = <String, dynamic>{};

        // Act
        final result = await FmeConfig.setSessionData(sessionData);

        // Assert
        expect(result, isTrue);
        expect(log.length, equals(1));
        expect(log[0].method, equals('setSessionData'));
        expect(log[0].arguments, equals(sessionData));
      });

      test('should handle complex session data', () async {
        // Arrange
        final sessionData = {
          'sessionId': 123456789,
          'userId': 'user123',
          'metadata': {
            'version': '1.0.0',
            'features': ['feature1', 'feature2'],
          },
        };

        // Act
        final result = await FmeConfig.setSessionData(sessionData);

        // Assert
        expect(result, isTrue);
        expect(log.length, equals(1));
        expect(log[0].method, equals('setSessionData'));
        expect(log[0].arguments, equals(sessionData));
      });

      test('should return false on PlatformException', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          throw PlatformException(
            code: 'SESSION_ERROR',
            message: 'Failed to set session data',
          );
        });

        final sessionData = {'sessionId': 123456789};

        // Act
        final result = await FmeConfig.setSessionData(sessionData);

        // Assert
        expect(result, isFalse);
      });

      test('should return false on general exception', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          throw Exception('Network error');
        });

        final sessionData = {'sessionId': 123456789};

        // Act
        final result = await FmeConfig.setSessionData(sessionData);

        // Assert
        expect(result, isFalse);
      });

      test('should return false on timeout', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          throw TimeoutException(
              'Method call timed out', const Duration(seconds: 30));
        });

        final sessionData = {'sessionId': 123456789};

        // Act
        final result = await FmeConfig.setSessionData(sessionData);

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
