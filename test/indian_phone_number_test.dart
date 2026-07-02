import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/auth/indian_phone_number.dart';

void main() {
  group('IndianPhoneNumber', () {
    test('accepts and normalizes exactly 10 digits', () {
      expect(IndianPhoneNumber.isValidLocal('9876543210'), isTrue);
      expect(IndianPhoneNumber.toE164('9876543210'), '+919876543210');
    });

    test('trims surrounding whitespace before normalization', () {
      expect(IndianPhoneNumber.toE164(' 9876543210 '), '+919876543210');
    });

    test('rejects invalid local numbers', () {
      for (final value in [
        '',
        '987654321',
        '98765432101',
        '98765abc10',
        '+919876543210',
      ]) {
        expect(
          IndianPhoneNumber.isValidLocal(value),
          isFalse,
          reason: 'Expected "$value" to be invalid',
        );
        expect(
          () => IndianPhoneNumber.toE164(value),
          throwsA(isA<FormatException>()),
        );
      }
    });
  });
}
