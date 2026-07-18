import 'dart:async';

import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';

/// Opening splash with a short branded intro. Auto-advances after 3s and can
/// be skipped (FR-1).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _advance);
  }

  void _advance() {
    if (_advanced || !mounted) return;
    _advanced = true;
    AppScope.of(context, listen: false).advanceFromSplash();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = context.s;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 52,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      s.tagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton(
                  onPressed: _advance,
                  child: Text(
                    s.skip,
                    style: TextStyle(color: scheme.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
