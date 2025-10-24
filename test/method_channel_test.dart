import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/vwo_fme_flutter_sdk_method_channel.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_user_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelVwoFmeFlutterSdk Tests', () {
    const MethodChannel channel = MethodChannel('vwo_fme_flutter_sdk');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'init':
            return null;
          case 'getFlag':
            return {
              'isEnabled': true,
              'variables': [
                {
                  'key': 'test_variable',
                  'value': 'test_value',
                  'type': 'string',
                }
              ]
            };
          case 'trackEvent':
            return {'success': true};
          case 'setAttribute':
            return true;
          case 'setSessionData':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      channel.setMockMethodCallHandler(null);
    });

    group('Initialization Tests', () {
      test('should initialize successfully with valid options', () async {
        // Arrange
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
        );

        // Act
        final result = await MethodChannelVwoFmeFlutterSdk.init(options);

        // Assert
        expect(result, isNotNull);
        expect(log, hasLength(2));
        expect(log.first.method, equals('init'));
        expect(log.first.arguments['sdkKey'], equals('test_sdk_key'));
        expect(log.first.arguments['accountId'], equals(12345));
        expect(log[1].method, equals('sendSdkInitEvent'));
      });

      test('should throw error for empty sdkKey', () async {
        // Arrange
        final options = VWOInitOptions(
          sdkKey: '',
          accountId: 12345,
        );

        // Act & Assert
        expect(
          () => MethodChannelVwoFmeFlutterSdk.init(options),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for invalid accountId', () async {
        // Arrange
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 0,
        );

        // Act & Assert
        expect(
          () => MethodChannelVwoFmeFlutterSdk.init(options),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for negative accountId', () async {
        // Arrange
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: -1,
        );

        // Act & Assert
        expect(
          () => MethodChannelVwoFmeFlutterSdk.init(options),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle initialization with logger configuration', () async {
        // Arrange
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
          logger: {
            'name': 'test_logger',
            'level': 'INFO',
            'prefix': 'VWO',
            'dateTimeFormat': 'yyyy-MM-dd HH:mm:ss',
            'transports': [
              {
                'defaultTransport': true,
              }
            ],
          },
        );

        // Act
        final result = await MethodChannelVwoFmeFlutterSdk.init(options);

        // Assert
        expect(result, isNotNull);
        expect(log, hasLength(2));
        expect(log.first.arguments['logger'], isNotNull);
        expect(log[1].method, equals('sendSdkInitEvent'));
      });

      test('should handle initialization with gateway service', () async {
        // Arrange
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
          gatewayService: {
            'url': 'https://api.vwo.com',
            'protocol': 'https',
            'port': '443',
          },
        );

        // Act
        final result = await MethodChannelVwoFmeFlutterSdk.init(options);

        // Assert
        expect(result, isNotNull);
        expect(log, hasLength(2));
        expect(log.first.arguments['gatewayService'], isNotNull);
        expect(log[1].method, equals('sendSdkInitEvent'));
      });

      test('should handle initialization with all optional parameters',
          () async {
        // Arrange
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
          pollInterval: 30,
          cachedSettingsExpiryTime: 3600,
          batchMinSize: 10,
          batchUploadTimeInterval: 5000,
          isUsageStatsDisabled: true,
        );

        // Act
        final result = await MethodChannelVwoFmeFlutterSdk.init(options);

        // Assert
        expect(result, isNotNull);
        expect(log, hasLength(2));
        final args = log.first.arguments;
        expect(args['pollInterval'], equals(30));
        expect(args['cachedSettingsExpiryTime'], equals(3600));
        expect(args['batchMinSize'], equals(10));
        expect(args['batchUploadTimeInterval'], equals('5000'));
        expect(args['isUsageStatsDisabled'], equals(true));
        expect(log[1].method, equals('sendSdkInitEvent'));
      });
    });

    group('GetFlag Tests', () {
      late MethodChannelVwoFmeFlutterSdk sdk;

      setUp(() async {
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
        );
        sdk = (await MethodChannelVwoFmeFlutterSdk.init(options))!;
      });

      test('should get flag successfully', () async {
        // Arrange
        final userContext = VWOUserContext(
          id: 'user123',
          customVariables: {'plan': 'premium'},
        );

        // Act
        final result = await sdk.getFlag(
          featureKey: 'test_feature',
          userContext: userContext,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.isEnabled(), isTrue);
        expect(result.getVariables(), hasLength(1));
        expect(log, hasLength(3)); // init + sendSdkInitEvent + getFlag
        expect(log.last.method, equals('getFlag'));
        expect(log.last.arguments['flagName'], equals('test_feature'));
      });

      test('should handle getFlag with complex user context', () async {
        // Arrange
        final userContext = VWOUserContext(
          id: 'user123',
          customVariables: {
            'user': {
              'profile': {
                'name': 'John',
                'age': 30,
                'preferences': ['dark_mode', 'notifications'],
              },
            },
            'session': {
              'id': 'sess_123',
              'startTime': DateTime.now().millisecondsSinceEpoch,
            },
          },
        );

        // Act
        final result = await sdk.getFlag(
          featureKey: 'complex_feature',
          userContext: userContext,
        );

        // Assert
        expect(result, isNotNull);
        expect(log.last.method, equals('getFlag'));
        expect(log.last.arguments['userContext']['id'], equals('user123'));
      });

      test('should handle getFlag with empty custom variables', () async {
        // Arrange
        final userContext = VWOUserContext(id: 'user123');

        // Act
        final result = await sdk.getFlag(
          featureKey: 'simple_feature',
          userContext: userContext,
        );

        // Assert
        expect(result, isNotNull);
        expect(log.last.arguments['userContext']['customVariables'], isNull);
      });
    });

    group('TrackEvent Tests', () {
      late MethodChannelVwoFmeFlutterSdk sdk;

      setUp(() async {
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
        );
        sdk = (await MethodChannelVwoFmeFlutterSdk.init(options))!;
      });

      test('should track event successfully', () async {
        // Arrange
        final userContext = VWOUserContext(
          id: 'user123',
          customVariables: {'plan': 'premium'},
        );

        // Act
        final result = await sdk.trackEvent(
          eventName: 'purchase_completed',
          userContext: userContext,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!['success'], isTrue);
        expect(log.last.method, equals('trackEvent'));
        expect(log.last.arguments['eventName'], equals('purchase_completed'));
      });

      test('should track event with properties', () async {
        // Arrange
        final userContext = VWOUserContext(id: 'user123');
        final eventProperties = {
          'amount': 99.99,
          'currency': 'USD',
          'product_id': 'prod_123',
        };

        // Act
        final result = await sdk.trackEvent(
          eventName: 'purchase_completed',
          userContext: userContext,
          eventProperties: eventProperties,
        );

        // Assert
        expect(result, isNotNull);
        expect(log.last.arguments['eventProperties'], equals(eventProperties));
      });

      test('should track event with complex properties', () async {
        // Arrange
        final userContext = VWOUserContext(id: 'user123');
        final eventProperties = {
          'cart': {
            'items': [
              {'id': 'item1', 'quantity': 2, 'price': 29.99},
              {'id': 'item2', 'quantity': 1, 'price': 19.99},
            ],
            'total': 79.97,
          },
          'user_segment': 'premium',
        };

        // Act
        final result = await sdk.trackEvent(
          eventName: 'cart_updated',
          userContext: userContext,
          eventProperties: eventProperties,
        );

        // Assert
        expect(result, isNotNull);
        expect(log.last.arguments['eventProperties'], equals(eventProperties));
      });
    });

    group('SetAttribute Tests', () {
      late MethodChannelVwoFmeFlutterSdk sdk;

      setUp(() async {
        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
        );
        sdk = (await MethodChannelVwoFmeFlutterSdk.init(options))!;
      });

      test('should set attribute successfully', () async {
        // Arrange
        final userContext = VWOUserContext(id: 'user123');
        final attributes = {
          'plan': 'premium',
          'age': 25,
          'location': 'US',
        };

        // Act
        final result = await sdk.setAttribute(
          attributes: attributes,
          userContext: userContext,
        );

        // Assert
        expect(result, isTrue);
        expect(log.last.method, equals('setAttribute'));
        expect(log.last.arguments['attributes'], equals(attributes));
      });

      test('should set attribute with complex values', () async {
        // Arrange
        final userContext = VWOUserContext(id: 'user123');
        final attributes = {
          'profile': {
            'name': 'John Doe',
            'email': 'john@example.com',
            'preferences': ['dark_mode', 'notifications'],
          },
          'subscription': {
            'plan': 'premium',
            'start_date': '2024-01-01',
            'features': ['feature1', 'feature2', 'feature3'],
          },
        };

        // Act
        final result = await sdk.setAttribute(
          attributes: attributes,
          userContext: userContext,
        );

        // Assert
        expect(result, isTrue);
        expect(log.last.arguments['attributes'], equals(attributes));
      });

      test('should set attribute with empty map', () async {
        // Arrange
        final userContext = VWOUserContext(id: 'user123');
        final attributes = <String, dynamic>{};

        // Act
        final result = await sdk.setAttribute(
          attributes: attributes,
          userContext: userContext,
        );

        // Assert
        expect(result, isTrue);
        expect(log.last.arguments['attributes'], equals(attributes));
      });
    });

    group('Error Handling Tests', () {
      test('should handle method channel errors gracefully', () async {
        // Arrange
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'TEST_ERROR',
            message: 'Test error message',
          );
        });

        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
        );

        // Act & Assert
        expect(
          () => MethodChannelVwoFmeFlutterSdk.init(options),
          throwsA(isA<PlatformException>()),
        );
      });

      test('should handle getFlag errors', () async {
        // Arrange
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'init') {
            return null;
          }
          throw PlatformException(
            code: 'FLAG_ERROR',
            message: 'Flag not found',
          );
        });

        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
        );
        final sdk = (await MethodChannelVwoFmeFlutterSdk.init(options))!;
        final userContext = VWOUserContext(id: 'user123');

        // Act & Assert
        expect(
          () => sdk.getFlag(
            featureKey: 'non_existent_flag',
            userContext: userContext,
          ),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('Integration Callback Tests', () {
      test('should handle integration callbacks', () async {
        // Arrange
        bool callbackCalled = false;
        Map<String, dynamic>? callbackData;

        final options = VWOInitOptions(
          sdkKey: 'test_sdk_key',
          accountId: 12345,
          integrations: (properties) {
            callbackCalled = true;
            callbackData = properties;
          },
        );

        // Act
        final sdk = await MethodChannelVwoFmeFlutterSdk.init(options);

        // Assert
        expect(sdk, isNotNull);
        expect(log.first.arguments['hasIntegrations'], isTrue);
      });
    });
  });
}
