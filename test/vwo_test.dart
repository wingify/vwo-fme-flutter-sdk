import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/vwo.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_user_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VWO Tests', () {
    late VWOInitOptions testOptions;
    late VWOUserContext testUserContext;
    const MethodChannel channel = MethodChannel('vwo_fme_flutter_sdk');

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

    tearDown(() {
      // Reset channel handler after each test
      channel.setMockMethodCallHandler(null);
    });

    group('init()', () {
      test('should initialize VWO successfully', () async {
        // Arrange
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          return null;
        });

        // Act
        final result = await VWO.init(testOptions);

        // Assert
        expect(result, isNotNull);
        expect(result, isA<VWO>());
      });

      test('should return null on initialization failure', () async {
        // Arrange
        channel.setMockMethodCallHandler((call) async {
          throw PlatformException(
              code: 'INIT_ERROR', message: 'Failed to initialize');
        });

        // Act
        final result = await VWO.init(testOptions);

        // Assert
        expect(result, isNull);
      });

      test('should return null on general exception', () async {
        // Arrange
        channel.setMockMethodCallHandler((call) async {
          throw Exception('General error');
        });

        // Act
        final result = await VWO.init(testOptions);

        // Assert
        expect(result, isNull);
      });
    });

    group('getFlag()', () {
      late VWO vwo;

      setUp(() async {
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'getFlag') {
            return {
              'isEnabled': true,
              'variables': [
                {'key': 'color', 'value': 'blue', 'type': 'string'}
              ]
            };
          }
          return null;
        });
        vwo = (await VWO.init(testOptions))!;
      });

      test('should return flag when successful', () async {
        // Arrange handler already returns isEnabled true + one variable

        // Act
        final result = await vwo.getFlag(
          featureKey: 'test-feature',
          context: testUserContext,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.isEnabled(), isTrue);
        expect(result.variables.length, equals(1));
        expect(result.variables[0].key, equals('color'));
        expect(result.variables[0].value, equals('blue'));
      });

      test('should throw on PlatformException', () async {
        // Arrange
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'getFlag') {
            throw PlatformException(code: 'ERROR', message: 'Flag not found');
          }
          return null;
        });
        vwo = (await VWO.init(testOptions))!;

        // Act & Assert
        expect(
          () => vwo.getFlag(
            featureKey: 'test-feature',
            context: testUserContext,
          ),
          throwsA(isA<PlatformException>()),
        );
      });

      test('should throw on general exception', () async {
        // Arrange
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'getFlag') {
            throw Exception('Network error');
          }
          return null;
        });
        vwo = (await VWO.init(testOptions))!;

        // Act & Assert
        expect(
          () => vwo.getFlag(
            featureKey: 'test-feature',
            context: testUserContext,
          ),
          // MethodChannel may wrap as PlatformException
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('trackEvent()', () {
      late VWO vwo;

      setUp(() async {
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'trackEvent') {
            return {'success': true};
          }
          return null;
        });
        vwo = (await VWO.init(testOptions))!;
      });

      test('should track event successfully', () async {
        // Arrange
        final eventProperties = {'price': 99.99, 'currency': 'USD'};
        final expectedResult = {'success': true};

        // Act
        final result = await vwo.trackEvent(
          eventName: 'purchase',
          context: testUserContext,
          eventProperties: eventProperties,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!['success'], isTrue);
      });

      test('should throw on PlatformException', () async {
        // Arrange
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'trackEvent') {
            throw PlatformException(code: 'ERROR', message: 'Tracking failed');
          }
          return null;
        });
        vwo = (await VWO.init(testOptions))!;

        // Act & Assert
        expect(
          () => vwo.trackEvent(
            eventName: 'purchase',
            context: testUserContext,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setAttribute()', () {
      late VWO vwo;

      setUp(() async {
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'setAttribute') return true;
          return null;
        });
        vwo = (await VWO.init(testOptions))!;
      });

      test('should set attribute successfully', () async {
        // Arrange
        final attributes = {'plan': 'premium', 'age': 30};

        // Act
        final result = await vwo.setAttribute(
          attributes: attributes,
          context: testUserContext,
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return false when platform is null', () async {
        // Arrange
        final vwoWithNullPlatform = VWO();
        final attributes = {'plan': 'premium'};

        // Act
        final result = await vwoWithNullPlatform.setAttribute(
          attributes: attributes,
          context: testUserContext,
        );

        // Assert
        expect(result, isFalse);
      });

      test('should throw on PlatformException', () async {
        // Arrange
        final attributes = {'plan': 'premium'};

        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'setAttribute') {
            throw PlatformException(
                code: 'ERROR', message: 'Set attribute failed');
          }
          return null;
        });
        vwo = (await VWO.init(testOptions))!;

        // Act & Assert
        expect(
          () => vwo.setAttribute(
            attributes: attributes,
            context: testUserContext,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('logMessage()', () {
      test('should log message in debug mode', () {
        // This test verifies the method exists and can be called
        // Since we can't easily test print statements, we just verify no exception is thrown
        expect(() => VWO.logMessage('Test message'), returnsNormally);
      });
    });
  });
}
