import 'dart:async';

import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/numpad.dart';
import 'tenant_select_screen.dart';

/// 6-digit OTP entry with auto-verification (FR-6). In this prototype **any**
/// code is accepted — there is no real SMS/OTP backend.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  // PROTOTİP (geçici): kod önceden "123456" dolu gelir; kullanıcı "Giriş Yap"a
  // basınca doğrulanır. Gerçek uygulamada bu alan boş başlar, kod SMS ile gelir.
  String _code = '123456';
  bool _verifying = false;

  void _onDigit(String d) {
    if (_verifying || _code.length >= _length) return;
    setState(() => _code += d);
    if (_code.length == _length) _verify();
  }

  void _onBackspace() {
    if (_verifying || _code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    // Brief delay to mimic verification; any code passes (mock).
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final state = AppScope.of(context, listen: false);
    final needsTenantSelect = state.verifyOtp();
    if (!mounted) return;
    if (needsTenantSelect) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TenantSelectScreen()),
      );
      // Reset so returning back lets the user retry.
      setState(() {
        _verifying = false;
        _code = '';
      });
    }
    // Otherwise selectTenant already flipped the phase; this flow is discarded.
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.otpTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                s.otpSubtitle(state.displayPhone),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_length, (i) {
                  final filled = i < _code.length;
                  return Container(
                    width: 44,
                    height: 54,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            filled ? scheme.primary : scheme.outlineVariant,
                        width: filled ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      filled ? _code[i] : '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              if (_verifying)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(s.verifying),
                  ],
                )
              else ...[
                // PROTOTİP (geçici): kod hazır geldiği için tek dokunuşla giriş.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _code.length == _length ? _verify : null,
                    child: const Text('Giriş Yap'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.resend)),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(s.resend),
                ),
              ],
              const Spacer(),
              Numpad(onDigit: _onDigit, onBackspace: _onBackspace),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
