final class IndianPhoneNumber {
  const IndianPhoneNumber._();

  static const countryCode = '+91';
  static final RegExp _localNumberPattern = RegExp(r'^\d{10}$');

  static bool isValidLocal(String value) {
    return _localNumberPattern.hasMatch(value.trim());
  }

  static String? tryParseLocal(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (isValidLocal(digits)) {
      return digits;
    }

    if (digits.length == 12 && digits.startsWith('91')) {
      final localNumber = digits.substring(2);
      if (isValidLocal(localNumber)) {
        return localNumber;
      }
    }

    return null;
  }

  static String toE164(String value) {
    final localNumber = value.trim();
    if (!isValidLocal(localNumber)) {
      throw const FormatException(
        'Indian mobile numbers must contain exactly 10 digits.',
      );
    }

    return '$countryCode$localNumber';
  }
}
