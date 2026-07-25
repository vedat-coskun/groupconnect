import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dev_config.dart';
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
    // DEBUG + kDevAutoLogin: restore bitince onboarding/giriş akışını atla ve
    // doğrudan ana ekrana düş (geliştirme kısayolu). Release'de asla çalışmaz.
    _state.restore().then((_) {
      if (kDebugMode && kDevAutoLogin && mounted) {
        _state.devAutoLogin(
          phone: kDevAutoLoginPhone,
          tenantId: kDevAutoLoginTenant,
        );
      }
    });
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
      // Tema, aktif kurumun görünüm ayarları + kullanıcı override'ından
      // REAKTİF kurulur: Builder AppScope'u dinler, appearance değişince
      // MaterialApp.theme yeniden çizilir (Navigator durumu korunur).
      child: Builder(
        builder: (context) {
          final appearance = AppScope.of(context).appearance;
          return MaterialApp(
            title: 'GroupConnect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(appearance),
            // Yazı boyutu ölçeği tüm metne burada uygulanır (tema yerine —
            // fontSize'ı null olan stillerde çökmez).
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(appearance.scale.factor),
                ),
                child: child!,
              );
            },
            home: const _RootGate(),
          );
        },
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
