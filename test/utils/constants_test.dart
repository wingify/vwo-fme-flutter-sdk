import 'package:flutter_test/flutter_test.dart';
import 'package:vwo_fme_flutter_sdk/utils/constants.dart';

void main() {
  group('Constants Tests', () {
    test('should have valid SDK version', () {
      // Assert
      expect(sdkVersion, isNotNull);
      expect(sdkVersion, isNotEmpty);
      expect(sdkVersion, isA<String>());
    });

    test('should follow semantic versioning format', () {
      // Assert
      expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(sdkVersion), isTrue);
    });

    test('should have non-zero version numbers', () {
      // Act
      final parts = sdkVersion.split('.');

      // Assert
      expect(parts.length, equals(3));
      final major = int.parse(parts[0]);
      final minor = int.parse(parts[1]);
      final patch = int.parse(parts[2]);

      expect(major, greaterThanOrEqualTo(0));
      expect(minor, greaterThanOrEqualTo(0));
      expect(patch, greaterThanOrEqualTo(0));
    });

    test('should be consistent across multiple accesses', () {
      // Act
      final version1 = sdkVersion;
      final version2 = sdkVersion;

      // Assert
      expect(version1, equals(version2));
    });
  });
}
