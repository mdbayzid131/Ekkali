import 'package:get/get.dart';

class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  // ===========================================================================
  // CORE VALIDATORS
  // ===========================================================================

  /// Validates that the value is not null or empty.
  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'This field is required';
    }
    return null;
  }

  /// Validates email format.
  static String? email(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password with optional complexity requirements.
  /// Default: Min 6 chars.
  static String? password(
    String? value, {
    int minLength = 6,
    bool requireDigit = false,
    bool requireUppercase = false,
    bool requireSpecialChar = false,
    String? message,
  }) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Password is required';
    }
    
    final password = value.trim();

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (requireDigit && !RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }

    if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (requireSpecialChar && !RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validates that the confirmation password matches the original password.
  static String? confirmPassword(String? value, String password, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Confirm password is required';
    }
    if (value.trim() != password.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ===========================================================================
  // IDENTITY & CONTACT VALIDATORS
  // ===========================================================================

  /// Validates full name (at least 3 chars).
  static String? name(String? value, {String? message, int minLength = 3}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Name is required';
    }
    if (value.trim().length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    // Optional: Check for valid name characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-\']+$").hasMatch(value.trim())) {
      return 'Enter a valid name';
    }
    return null;
  }

  /// Validates username (alphanumeric + underscore, min 3 chars).
  static String? username(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  /// Validates phone number (enforces 10-digit US phone format: (XXX) XXX-XXXX).
  static String? phone(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Phone number is required';
    }
    final phone = value.trim();

    // Regular expression to allow digits, +, (, ), -, and spaces
    final phoneRegex = RegExp(r'^[+0-9()-\s]+$');

    if (!phoneRegex.hasMatch(phone)) {
      return 'Enter a valid phone number';
    }

    String digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      digitsOnly = digitsOnly.substring(1);
    }
    if (digitsOnly.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  /// Validates URL.
  static String? url(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is usually optional, return null if empty. Use required() if needed.
    }
    if (!GetUtils.isURL(value.trim())) {
      return message ?? 'Enter a valid URL';
    }
    return null;
  }

  // ===========================================================================
  // FINANCE & CARD VALIDATORS
  // ===========================================================================

  /// Validates Credit Card Number (Length 13-19 digits).
  /// Note: For strict validation, implement Luhn algorithm.
  static String? creditCard(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Card number is required';
    }
    final cleanValue = value.replaceAll(RegExp(r'\s+\-'), '');
    if (!RegExp(r'^[0-9]{13,19}$').hasMatch(cleanValue)) {
      return 'Enter a valid card number';
    }
    return null;
  }

  /// Validates CVV (3 or 4 digits).
  static String? cvv(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'CVV is required';
    }
    if (!RegExp(r'^[0-9]{3,4}$').hasMatch(value.trim())) {
      return 'Enter a valid CVV';
    }
    return null;
  }

  /// Validates Card Expiry Date (MM/YY or MM/YYYY).
  static String? expiryDate(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Expiry date is required';
    }
    
    // Pattern: MM/YY or MM/YYYY
    if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2}|[0-9]{4})$').hasMatch(value.trim())) {
      return 'Enter valid date (MM/YY)';
    }

    // Advanced: Check if date is in the future
    // Implementation would require parsing date logic
    return null;
  }

  /// Validates monetary amount.
  static String? amount(String? value, {String? message, double min = 0}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Amount is required';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Enter a valid amount';
    }
    if (number < min) {
      return 'Amount must be at least $min';
    }
    return null;
  }

  // ===========================================================================
  // NUMERIC & RANGE VALIDATORS
  // ===========================================================================

  /// Validates if value is a number.
  static String? phoneNumber(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!GetUtils.isPhoneNumber(value.trim())) {
      return message ?? 'Enter a valid number';
    }
    return null;
  }

  /// Validates year within a range (e.g., last 5 years).
  static String? year(String? value, {int? min, int? max, String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Year is required';
    }
    final yearValue = int.tryParse(value.trim());
    if (yearValue == null) {
      return 'Enter a valid year';
    }
    if (min != null && yearValue < min) {
      return 'Year must be $min or later';
    }
    if (max != null && yearValue > max) {
      return 'Year cannot be after $max';
    }
    return null;
  }

  /// Validates integer only.
  static String? integer(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return message ?? 'Enter a valid integer';
    }
    return null;
  }

  // ===========================================================================
  // OTHER VALIDATORS
  // ===========================================================================

  /// Validates OTP (Usually 4 or 6 digits).
  static String? otp(String? value, {int length = 6, String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Enter OTP';
    }
    if (value.trim().length != length) {
      return 'OTP must be $length digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return 'OTP must be digits only';
    }
    return null;
  }

  /// Validates minimum length.
  static String? minLength(String? value, int min, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'This field is required';
    }
    if (value.trim().length < min) {
      return 'Must be at least $min characters';
    }
    return null;
  }

  /// Validates maximum length.
  static String? maxLength(String? value, int max, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.trim().length > max) {
      return 'Must be at most $max characters';
    }
    return null;
  }
}
