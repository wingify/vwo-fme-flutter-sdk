import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/wingify.dart';
import 'package:vwo_fme_flutter_sdk/wingify/models/wingify_init_options.dart';
import 'package:vwo_fme_flutter_sdk/wingify/models/wingify_user_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Wingify Tests', () {
    late WingifyInitOptions testOptions;
    late WingifyUserContext testUserContext;
    const MethodChannel channel = MethodChannel('vwo_fme_flutter_sdk');

    setUp(() {
      testOptions = WingifyInitOptions(
        sdkKey: 'test-sdk-key',
        accountId: 12345,
        logger: {'level': 'ERROR'},
        pollInterval: 30000,
      );

      testUserContext = WingifyUserContext(
        id: 'test-user-123',
        customVariables: {'plan': 'premium', 'age': 25},
      );
    });

    tearDown(() {
      channel.setMockMethodCallHandler(null);
    });

    test('useWingifyApi flag should be true for WingifyInitOptions', () {
      expect(testOptions.useWingifyApi, isTrue);
    });

    group('init()', () {
      test('should initialize Wingify successfully', () async {
        // Arrange
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          return null;
        });

        // Act
        final result = await Wingify.init(testOptions);

        // Assert
        expect(result, isNotNull);
        expect(result, isA<Wingify>());
      });

      test('should send useWingifyApi=true on init', () async {
        // Arrange
        bool? sentFlag;
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') {
            sentFlag = call.arguments['useWingifyApi'] as bool?;
          }
          return null;
        });

        // Act
        await Wingify.init(testOptions);

        // Assert
        expect(sentFlag, isTrue);
      });

      test('should return null on initialization failure', () async {
        // Arrange
        channel.setMockMethodCallHandler((call) async {
          throw PlatformException(
              code: 'INIT_ERROR', message: 'Failed to initialize');
        });

        // Act
        final result = await Wingify.init(testOptions);

        // Assert
        expect(result, isNull);
      });
    });

    group('getFlag()', () {
      late Wingify wingify;

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
        wingify = (await Wingify.init(testOptions))!;
      });

      test('should return flag when successful', () async {
        // Act
        final result = await wingify.getFlag(
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

      test('should send useWingifyApi=true on getFlag', () async {
        // Arrange
        bool? sentFlag;
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'getFlag') {
            sentFlag = call.arguments['useWingifyApi'] as bool?;
            return {'isEnabled': true, 'variables': []};
          }
          return null;
        });
        wingify = (await Wingify.init(testOptions))!;

        // Act
        await wingify.getFlag(
          featureKey: 'test-feature',
          context: testUserContext,
        );

        // Assert
        expect(sentFlag, isTrue);
      });
    });

    group('trackEvent()', () {
      late Wingify wingify;

      setUp(() async {
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'trackEvent') {
            return {'success': true};
          }
          return null;
        });
        wingify = (await Wingify.init(testOptions))!;
      });

      test('should track event successfully', () async {
        // Act
        final result = await wingify.trackEvent(
          eventName: 'purchase',
          context: testUserContext,
          eventProperties: {'price': 99.99, 'currency': 'USD'},
        );

        // Assert
        expect(result, isNotNull);
        expect(result!['success'], isTrue);
      });
    });

    group('setAttribute()', () {
      late Wingify wingify;

      setUp(() async {
        channel.setMockMethodCallHandler((call) async {
          if (call.method == 'init') return null;
          if (call.method == 'setAttribute') return true;
          return null;
        });
        wingify = (await Wingify.init(testOptions))!;
      });

      test('should set attribute successfully', () async {
        // Act
        final result = await wingify.setAttribute(
          attributes: {'plan': 'premium', 'age': 30},
          context: testUserContext,
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return false when platform is null', () async {
        // Arrange
        final wingifyWithNullPlatform = Wingify();

        // Act
        final result = await wingifyWithNullPlatform.setAttribute(
          attributes: {'plan': 'premium'},
          context: testUserContext,
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('logMessage()', () {
      test('should log message without throwing', () {
        expect(() => Wingify.logMessage('Test message'), returnsNormally);
      });
    });
  });
}
