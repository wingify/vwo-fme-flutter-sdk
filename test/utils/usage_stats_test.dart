import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/utils/usage_stats.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';

void main() {
  group('UsageStats Tests', () {
    late VWOInitOptions testOptions;

    setUp(() {
      testOptions = VWOInitOptions(
        sdkKey: 'test-sdk-key',
        accountId: 12345,
      );
    });

    test('should create instance with init options', () {
      // Act
      final usageStats = UsageStats(testOptions);

      // Assert
      expect(usageStats, isNotNull);
      expect(usageStats.initOptions, equals(testOptions));
    });

    test('should collect stats when usage stats is enabled', () async {
      // Arrange
      testOptions.isUsageStatsDisabled = false;
      final usageStats = UsageStats(testOptions);

      // Act
      final stats = await usageStats.getStats();

      // Assert
      expect(stats, isNotNull);
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('lv'), isTrue);
      expect(stats['lv'], contains('Dart'));
    });

    test('should return empty map when usage stats is disabled', () async {
      // Arrange
      testOptions.isUsageStatsDisabled = true;
      final usageStats = UsageStats(testOptions);

      // Act
      final stats = await usageStats.getStats();

      // Assert
      expect(stats, isNotNull);
      expect(stats, isEmpty);
    });

    test('should include dart version in stats', () async {
      // Arrange
      testOptions.isUsageStatsDisabled = false;
      final usageStats = UsageStats(testOptions);

      // Act
      final stats = await usageStats.getStats();

      // Assert
      expect(stats['lv'], isNotNull);
      expect(stats['lv'], isA<String>());
      expect(stats['lv'], startsWith('Dart '));
      // Should contain a version number
      expect(RegExp(r'Dart \d+\.\d+\.\d+').hasMatch(stats['lv'] as String),
          isTrue);
    });

    test('should merge stats with existing vwo_meta', () async {
      // Arrange
      testOptions.isUsageStatsDisabled = false;
      testOptions.vwo_meta['existing_key'] = 'existing_value';
      testOptions.vwo_meta['another_key'] = 123;
      final usageStats = UsageStats(testOptions);

      // Act
      final stats = await usageStats.getStats();

      // Assert
      expect(stats['existing_key'], equals('existing_value'));
      expect(stats['another_key'], equals(123));
      expect(stats['lv'], isNotNull);
      expect(stats.length, greaterThanOrEqualTo(3));
    });

    test('should handle multiple calls consistently', () async {
      // Arrange
      testOptions.isUsageStatsDisabled = false;
      final usageStats = UsageStats(testOptions);

      // Act
      final stats1 = await usageStats.getStats();
      final stats2 = await usageStats.getStats();

      // Assert
      expect(stats1['lv'], equals(stats2['lv']));
      expect(stats1.length, equals(stats2.length));
    });

    test('should work with different init options', () async {
      // Arrange
      final options1 = VWOInitOptions(sdkKey: 'key1', accountId: 1);
      final options2 = VWOInitOptions(sdkKey: 'key2', accountId: 2);
      options1.isUsageStatsDisabled = false;
      options2.isUsageStatsDisabled = false;
      options1.vwo_meta['custom1'] = 'value1';
      options2.vwo_meta['custom2'] = 'value2';

      final usageStats1 = UsageStats(options1);
      final usageStats2 = UsageStats(options2);

      // Act
      final stats1 = await usageStats1.getStats();
      final stats2 = await usageStats2.getStats();

      // Assert
      expect(stats1['custom1'], equals('value1'));
      expect(stats2['custom2'], equals('value2'));
      expect(stats1.containsKey('custom2'), isFalse);
      expect(stats2.containsKey('custom1'), isFalse);
      expect(stats1['lv'], equals(stats2['lv'])); // Same Dart version
    });

    test('should handle options with pre-existing lv key', () async {
      // Arrange
      testOptions.isUsageStatsDisabled = false;
      testOptions.vwo_meta['lv'] = 'existing_language_version';
      final usageStats = UsageStats(testOptions);

      // Act
      final stats = await usageStats.getStats();

      // Assert
      // The new Dart version should override the existing one
      expect(stats['lv'], isNot(equals('existing_language_version')));
      expect(stats['lv'], startsWith('Dart '));
    });

    test('should return different instances for different options', () {
      // Arrange
      final options1 = VWOInitOptions(sdkKey: 'key1', accountId: 1);
      final options2 = VWOInitOptions(sdkKey: 'key2', accountId: 2);

      // Act
      final usageStats1 = UsageStats(options1);
      final usageStats2 = UsageStats(options2);

      // Assert
      expect(usageStats1, isNot(same(usageStats2)));
      expect(usageStats1.initOptions, isNot(same(usageStats2.initOptions)));
    });

    test('should handle disabled stats consistently across multiple calls',
        () async {
      // Arrange
      testOptions.isUsageStatsDisabled = true;
      final usageStats = UsageStats(testOptions);

      // Act
      final stats1 = await usageStats.getStats();
      final stats2 = await usageStats.getStats();
      final stats3 = await usageStats.getStats();

      // Assert
      expect(stats1, isEmpty);
      expect(stats2, isEmpty);
      expect(stats3, isEmpty);
    });
  });
}
