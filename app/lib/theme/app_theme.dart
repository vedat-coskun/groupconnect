import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Görünüm (appearance) — admin-parametrik + kullanıcı override edilebilen üç
/// eksen: vurgu rengi, yazı boyutu, yazı tipi (kullanıcı tercihi 2026-07-19).
/// Etkin değer, [app_state] tarafından (admin kilidi/kullanıcı seçimi) hesaplanır.
class Appearance {
  const Appearance({
    required this.accent,
    required this.scale,
    required this.fontFamily,
  });

  /// Vurgu (seed) rengi — ColorScheme bundan türetilir.
  final Color accent;

  /// Yazı boyutu ölçeği.
  final AppTextScale scale;

  /// Yazı tipi ailesi; null = sistem varsayılanı.
  final String? fontFamily;

  /// Tenant seçilmeden önce (splash/auth) kullanılan yansız varsayılan.
  static const Appearance fallback = Appearance(
    accent: AppTheme.seed,
    scale: AppTextScale.medium,
    fontFamily: null,
  );
}

/// Admin'in görünüm için sunduğu vurgu-rengi paleti (prototip). İlk öğe
/// jeneriktir; kurum markası buna eklenir.
const List<Color> kAccentPalette = [
  Color(0xFF3D5AFE), // indigo (varsayılan)
  Color(0xFF2E7D6B), // teal
  Color(0xFF7A4FB6), // mor
  Color(0xFFB0413E), // kırmızı
  Color(0xFFB07B3A), // amber/altın
  Color(0xFF3A6FD8), // mavi
  Color(0xFF2E7D32), // yeşil
  Color(0xFFC2185B), // pembe
];

/// Yazı tipi seçenekleri — (etiket, aile). Aile null = sistem. Prototipte iOS
/// sistem fontları kullanılır (asset paketlemeden çalışır).
const List<(String, String?)> kFontOptions = [
  ('Sistem', null),
  ('Georgia', 'Georgia'),
  ('Courier', 'Courier New'),
  ('Times', 'Times New Roman'),
];

/// One coherent Material 3 theme, parametrik görünümden (Appearance) kurulur.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF3D5AFE); // indigo/blue accent (varsayılan)

  /// Görünümden tema kur (vurgu rengi + font). NOT: yazı boyutu ölçeği burada
  /// UYGULANMAZ — `textTheme.apply(fontSizeFactor:)` fontSize'ı null olan
  /// stillerde assertion attırır. Ölçek, app.dart'ta `MediaQuery.textScaler`
  /// ile tüm metne güvenle uygulanır ([Appearance.scale]).
  static ThemeData build(Appearance a) {
    final scheme = ColorScheme.fromSeed(
      seedColor: a.accent,
      brightness: Brightness.light,
    );
    return _base(scheme, fontFamily: a.fontFamily);
  }

  static ThemeData light() => build(Appearance.fallback);

  static ThemeData _base(ColorScheme scheme, {String? fontFamily}) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
