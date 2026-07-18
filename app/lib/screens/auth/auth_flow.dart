import 'package:flutter/material.dart';

import 'phone_screen.dart';

/// Self-contained authentication navigator (phone -> OTP -> tenant select).
///
/// Kept as a nested [Navigator] so back-navigation works between steps and so
/// the whole flow is discarded cleanly when [AppState] flips the phase to
/// home/profileSetup after a successful login.
class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute:
          (settings) => MaterialPageRoute(
            builder: (_) => const PhoneScreen(),
            settings: settings,
          ),
    );
  }
}
