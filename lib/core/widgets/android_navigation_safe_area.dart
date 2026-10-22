import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Keeps the Android navigator, including its modal routes, above system buttons.
/// SafeArea consumes the inset so existing page-level SafeAreas do not add it twice.
class AndroidNavigationSafeArea extends StatelessWidget {
  final Widget child;

  const AndroidNavigationSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return child;
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(top: false, left: false, right: false, child: child),
    );
  }
}
