import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/utils/sdk_info.dart';

void main() {
  group('SDKInfoUtils Tests', () {
    late SDKInfoUtils sdkInfoUtils;

    setUp(() {
      sdkInfoUtils = SDKInfoUtils();
    });

    test('should return dart version', () {
      // Act
      final version = sdkInfoUtils.getDartVersion();

      // Assert
      expect(version, isNotNull);
      expect(version, isNotEmpty);
      expect(version, isA<String>());
      // Should contain the actual Platform.version value
      expect(version, equals(Platform.version));
    });

    test('should extract clean dart version from full version string', () {
      // Act
      final cleanVersion = sdkInfoUtils.getCleanDartVersion();

      // Assert
      expect(cleanVersion, isNotNull);
      expect(cleanVersion, isNotEmpty);
      expect(cleanVersion, isA<String>());
      // Should be in semantic version format (x.y.z)
      expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(cleanVersion), isTrue);
    });

    test('should handle version extraction correctly', () {
      // The clean version should be extractable from the full version
      final fullVersion = sdkInfoUtils.getDartVersion();
      final cleanVersion = sdkInfoUtils.getCleanDartVersion();

      // If a clean version is returned, it should be contained in the full version
      if (cleanVersion.isNotEmpty && cleanVersion != fullVersion) {
        expect(fullVersion, contains(cleanVersion));
      }
    });

    test('should return consistent results on multiple calls', () {
      // Act
      final version1 = sdkInfoUtils.getDartVersion();
      final version2 = sdkInfoUtils.getDartVersion();
      final cleanVersion1 = sdkInfoUtils.getCleanDartVersion();
      final cleanVersion2 = sdkInfoUtils.getCleanDartVersion();

      // Assert
      expect(version1, equals(version2));
      expect(cleanVersion1, equals(cleanVersion2));
    });

    test('should handle empty or malformed version gracefully', () {
      // This test verifies that the regex matching doesn't crash
      // We can't easily mock Platform.version, but we can verify the method handles edge cases
      expect(() => sdkInfoUtils.getCleanDartVersion(), returnsNormally);
    });

    test('should return valid semantic version format', () {
      // Act
      final cleanVersion = sdkInfoUtils.getCleanDartVersion();

      // Assert
      if (cleanVersion.isNotEmpty) {
        // Should match semantic versioning pattern
        final parts = cleanVersion.split('.');
        expect(parts.length, equals(3));
        for (final part in parts) {
          expect(int.tryParse(part), isNotNull);
        }
      }
    });

    test('should create multiple instances independently', () {
      // Arrange
      final utils1 = SDKInfoUtils();
      final utils2 = SDKInfoUtils();

      // Act
      final version1 = utils1.getDartVersion();
      final version2 = utils2.getDartVersion();

      // Assert
      expect(version1, equals(version2));
      expect(utils1, isNot(same(utils2))); // Different instances
    });
  });
}
