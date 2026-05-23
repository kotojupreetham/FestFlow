import 'package:flutter_test/flutter_test.dart';
import 'package:festflow/global.dart';

void main() {
  group('GlobalState White Box Tests', () {
    setUp(() {
      // Reset the global state before each test
      GlobalState.activeEventCode = null;
    });

    test('activeEventCode starts as null', () {
      expect(GlobalState.activeEventCode, isNull);
    });

    test('activeEventCode can be updated and read globally', () {
      // Act
      String mockEventCode = "COLLE-12345";
      GlobalState.activeEventCode = mockEventCode;

      // Assert
      expect(GlobalState.activeEventCode, equals("COLLE-12345"));
    });

    test('activeEventCode can be cleared upon logout simulation', () {
      // Arrange
      GlobalState.activeEventCode = "TEST-999";
      expect(GlobalState.activeEventCode, isNotNull);

      // Act
      GlobalState.activeEventCode = null;

      // Assert
      expect(GlobalState.activeEventCode, isNull);
    });
  });
}
