import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/vwo.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_user_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VWO Simple Tests', () {
    late VWOInitOptions testOptions;
    late VWOUserContext testUserContext;

    setUp(() {
      testOptions = VWOInitOptions(
        sdkKey: 'test-sdk-key',
        accountId: 12345,
        logger: {'level': 'ERROR'},
        pollInterval: 30000,
      );

      testUserContext = VWOUserContext(
        id: 'test-user-123',
        customVariables: {'plan': 'premium', 'age': 25},
      );
    });

    group('VWO Class', () {
      test('should create VWO instance', () {
        // Act
        final vwo = VWO();

        // Assert
        expect(vwo, isNotNull);
        expect(vwo, isA<VWO>());
      });

      test('should handle initialization with invalid parameters gracefully',
          () async {
        // Test with empty SDK key
        final invalidOptions = VWOInitOptions(
          sdkKey: '',
          accountId: 12345,
        );

        // Act
        final result = await VWO.init(invalidOptions);

        // Assert
        // Should return null due to validation error or platform exception
        expect(result, isNull);
      });

      test('should handle initialization with invalid account ID gracefully',
          () async {
        // Test with invalid account ID
        final invalidOptions = VWOInitOptions(
          sdkKey: 'valid-key',
          accountId: -1,
        );

        // Act
        final result = await VWO.init(invalidOptions);

        // Assert
        // Should return null due to validation error or platform exception
        expect(result, isNull);
      });
    });

    group('VWO Static Methods', () {
      test('should log message without throwing exception', () {
        // Act & Assert
        expect(() => VWO.logMessage('Test message'), returnsNormally);
        expect(() => VWO.logMessage(''), returnsNormally);
        expect(
            () => VWO.logMessage('Very long message ' * 100), returnsNormally);
      });

      test('should handle null or empty log messages', () {
        // Act & Assert
        expect(() => VWO.logMessage(''), returnsNormally);
      });

      test('should handle special characters in log messages', () {
        // Act & Assert
        expect(() => VWO.logMessage('Message with special chars: !@#\$%^&*()'),
            returnsNormally);
        expect(() => VWO.logMessage('Unicode: 🚀 🌟 ✨ 中文 العربية'),
            returnsNormally);
      });
    });

    group('Platform Integration Tests', () {
      test('should handle platform communication errors gracefully', () async {
        // These tests verify that the VWO class handles platform channel
        // communication errors without crashing

        final vwo = VWO();

        // Test getFlag with null platform
        final flagResult = await vwo.getFlag(
          featureKey: 'test-feature',
          context: testUserContext,
        );
        expect(flagResult, isNull);

        // Test trackEvent with null platform
        final trackResult = await vwo.trackEvent(
          eventName: 'test-event',
          context: testUserContext,
        );
        expect(trackResult, isNull);

        // Test setAttribute with null platform
        final attrResult = await vwo.setAttribute(
          attributes: {'key': 'value'},
          context: testUserContext,
        );
        expect(attrResult, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle various error scenarios in initialization', () async {
        // Test various invalid configurations
        final testCases = [
          VWOInitOptions(sdkKey: '', accountId: 0), // Empty key, zero account
          VWOInitOptions(sdkKey: 'key', accountId: -1), // Negative account
          VWOInitOptions(sdkKey: ' ', accountId: 123), // Whitespace key
        ];

        for (final options in testCases) {
          final result = await VWO.init(options);
          expect(result, isNull,
              reason:
                  'Should return null for invalid options: ${options.toString()}');
        }
      });
    });

    group('Integration', () {
      test('should work with valid VWO options and user context', () {
        // Test that objects can be created and basic operations work
        expect(() {
          final options = VWOInitOptions(
            sdkKey: 'valid-sdk-key',
            accountId: 12345,
            logger: {'level': 'INFO'},
            pollInterval: 30000,
            cachedSettingsExpiryTime: 60000,
            isUsageStatsDisabled: false,
          );

          final userContext = VWOUserContext(
            id: 'user-123',
            customVariables: {
              'plan': 'premium',
              'age': 25,
              'country': 'US',
            },
          );

          // Verify objects are created successfully
          expect(options.sdkKey, equals('valid-sdk-key'));
          expect(options.accountId, equals(12345));
          expect(userContext.id, equals('user-123'));
          expect(userContext.customVariables!['plan'], equals('premium'));
        }, returnsNormally);
      });
    });
  });
}
