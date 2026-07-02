import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  /// Theme shortcut
  ThemeData get theme => Theme.of(this);

  /// ColorScheme shortcut
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// TextTheme shortcut
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// MediaQuery shortcut
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;

  EdgeInsets get viewPadding => mediaQuery.viewPadding;

  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 720;

  /// Show a simple SnackBar
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        duration: duration,
      ),
    );
  }
}

extension StringX on String {
  /// Whether this string is a valid email address
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Whether this string is a non-empty, trimmed string
  bool get isNotBlank => trim().isNotEmpty;
}

extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
