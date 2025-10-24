import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';

void main() {
  group('VWOInitOptions Tests', () {
    test('should create instance with required parameters', () {
      // Act
      final options = VWOInitOptions(
        sdkKey: 'test-sdk-key',
        accountId: 12345,
      );

      // Assert
      expect(options.sdkKey, equals('test-sdk-key'));
      expect(options.accountId, equals(12345));
      expect(options.logger, isNull);
      expect(options.gatewayService, isNull);
      expect(options.pollInterval, isNull);
      expect(options.cachedSettingsExpiryTime, isNull);
      expect(options.integrations, isNull);
      expect(options.batchMinSize, equals(-1));
      expect(options.batchUploadTimeInterval, equals(-1));
      expect(options.isUsageStatsDisabled, isFalse);
      expect(options.vwo_meta, isEmpty);
    });

    test('should create instance with all parameters', () {
      // Arrange
      final logger = {'level': 'DEBUG'};
      final gatewayService = {'url': 'https://gateway.vwo.com'};
      final integrations = (Map<String, dynamic> props) => {};

      // Act
      final options = VWOInitOptions(
        sdkKey: 'test-sdk-key',
        accountId: 12345,
        logger: logger,
        gatewayService: gatewayService,
        pollInterval: 30000,
        cachedSettingsExpiryTime: 60000,
        integrations: integrations,
        batchMinSize: 10,
        batchUploadTimeInterval: 120000,
        isUsageStatsDisabled: true,
      );

      // Assert
      expect(options.sdkKey, equals('test-sdk-key'));
      expect(options.accountId, equals(12345));
      expect(options.logger, equals(logger));
      expect(options.gatewayService, equals(gatewayService));
      expect(options.pollInterval, equals(30000));
      expect(options.cachedSettingsExpiryTime, equals(60000));
      expect(options.integrations, equals(integrations));
      expect(options.batchMinSize, equals(10));
      expect(options.batchUploadTimeInterval, equals(120000));
      expect(options.isUsageStatsDisabled, isTrue);
    });

    test('should allow modification of vwo_meta', () {
      // Arrange
      final options = VWOInitOptions(
        sdkKey: 'test-sdk-key',
        accountId: 12345,
      );

      // Act
      options.vwo_meta['test'] = 'value';

      // Assert
      expect(options.vwo_meta['test'], equals('value'));
    });

    test('should generate correct toString representation', () {
      // Arrange
      final options = VWOInitOptions(
        sdkKey: 'test-sdk-key',
        accountId: 12345,
        logger: {'level': 'DEBUG'},
        pollInterval: 30000,
        integrations: (Map<String, dynamic> props) => {},
      );

      // Act
      final result = options.toString();

      // Assert
      expect(result, contains('VWOInitOptions('));
      expect(result, contains('sdkKey: test-sdk-key'));
      expect(result, contains('accountId: 12345'));
      expect(result, contains('logger: {level: DEBUG}'));
      expect(result, contains('pollInterval: 30000'));
      expect(result, contains('integrationCallback: Provided'));
    });

    test('should show "Not Provided" for null integrations in toString', () {
      // Arrange
      final options = VWOInitOptions(
        sdkKey: 'test-sdk-key',
        accountId: 12345,
      );

      // Act
      final result = options.toString();

      // Assert
      expect(result, contains('integrationCallback: Not Provided'));
    });
  });
}
