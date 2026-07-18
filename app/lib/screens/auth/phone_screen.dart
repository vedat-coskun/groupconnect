import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/numpad.dart';
import 'otp_screen.dart';

/// Country dial metadata. Length rules validate the number (FR-3). A real app
/// would source these from the backend (NFR-15); here they are a small
/// in-memory list.
class _Country {
  const _Country(this.flag, this.name, this.code, this.min, this.max);
  final String flag;
  final String name;
  final String code;
  final int min;
  final int max;
}

const _countries = <_Country>[
  _Country('🇹🇷', 'Türkiye', '+90', 10, 10),
  _Country('🇺🇸', 'United States', '+1', 10, 10),
  _Country('🇩🇪', 'Deutschland', '+49', 10, 11),
  _Country('🇬🇧', 'United Kingdom', '+44', 10, 10),
];

/// Phone-number entry: country code + numpad (FR-2, FR-3).
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  _Country _country = _countries.first;
  // PROTOTİP (geçici): numara 9 hane hazır gelir (…0); son tek haneyi yazınca
  // kimlik seçilir ve otomatik ilerler → 1=Vedat, 2=Suden, 3=Arda. Gerçekte boş.
  String _number = '555555550';

  bool get _valid =>
      _number.length >= _country.min && _number.length <= _country.max;

  void _onDigit(String d) {
    if (_number.length >= _country.max) return;
    setState(() => _number += d);
    // PROTOTİP (geçici): son hane girilince otomatik olarak OTP ekranına geç.
    if (_number.length == _country.max) _continue();
  }

  void _onBackspace() {
    if (_number.isEmpty) return;
    setState(() => _number = _number.substring(0, _number.length - 1));
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in _countries)
                  ListTile(
                    leading: Text(
                      c.flag,
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(c.name),
                    trailing: Text(c.code),
                    onTap: () => Navigator.pop(context, c),
                  ),
              ],
            ),
          ),
    );
    if (picked != null) {
      setState(() {
        _country = picked;
        _number = '';
      });
    }
  }

  void _continue() {
    AppScope.of(context, listen: false).setPendingPhone(_country.code, _number);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OtpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.phoneTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                s.phoneSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _pickCountry,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 18,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _country.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 6),
                        Text(_country.code),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 56,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _number.isEmpty ? '5xx xxx xx xx' : _number,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          letterSpacing: 1.5,
                          color:
                              _number.isEmpty
                                  ? scheme.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  )
                                  : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                s.phoneHelp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Numpad(onDigit: _onDigit, onBackspace: _onBackspace),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _valid ? _continue : null,
                child: Text(s.continueLabel),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
