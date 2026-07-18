import 'package:flutter/material.dart';

import 'screens/auth/auth_flow.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/auth/tenant_select_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/shell/home_shell.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

/// Root application widget. Owns the single [AppState] instance and injects it
/// through [AppScope].
class GroupConnectApp extends StatefulWidget {
  const GroupConnectApp({super.key});

  @override
  State<GroupConnectApp> createState() => _GroupConnectAppState();
}

class _GroupConnectAppState extends State<GroupConnectApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    // Diske kaydedilmiş rehber/favorileri geri yükle (açılışta, splash sürerken).
    _state.restore();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'GroupConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const _RootGate(),
      ),
    );
  }
}

/// Chooses the top-level screen based on [AppState.phase].
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final Widget child = switch (state.phase) {
      AppPhase.splash => const SplashScreen(),
      AppPhase.onboarding => const OnboardingScreen(),
      AppPhase.auth => const AuthFlow(),
      AppPhase.tenantSelect => const TenantSelectScreen(),
      AppPhase.profileSetup => const ProfileSetupScreen(),
      AppPhase.home => const HomeShell(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(key: ValueKey(state.phase), child: child),
    );
  }
}
