final class IndianPhoneNumber {
  const IndianPhoneNumber._();

  static const countryCode = '+91';
  static final RegExp _localNumberPattern = RegExp(r'^\d{10}$');

  static bool isValidLocal(String value) {
    return _localNumberPattern.hasMatch(value.trim());
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
