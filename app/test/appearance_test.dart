// Görünüm (appearance) — admin-parametrik + kullanıcı override (kullanıcı
// tercihi 2026-07-19). Etkin değer: admin ekseni kilitliyse admin değeri;
// değilse kullanıcı seçimi (yoksa admin varsayılanı).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/models/enums.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  test('tenant seçilmeden fallback görünüm', () {
    final s = AppState();
    // Aktif kurum yok → fallback (seed rengi, orta boyut, sistem font).
    expect(s.appearance.scale, AppTextScale.medium);
    expect(s.appearance.fontFamily, isNull);
  });

  test('varsayılan = kurum markası; kilit yokken kullanıcı override eder', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('uni');

    // Admin varsayılanı kurum markasından (Atlas Üniversitesi = 0xFF1F4E8C).
    expect(s.appearance.accent, const Color(0xFF1F4E8C));
    expect(s.canUserSetAccent, isTrue);

    // Kullanıcı kendi rengini seçer → etkin değer değişir.
    s.setUserAccent(const Color(0xFFC2185B));
    expect(s.appearance.accent, const Color(0xFFC2185B));

    // Kurum varsayılanına dön.
    s.setUserAccent(null);
    expect(s.appearance.accent, const Color(0xFF1F4E8C));
  });

  test('admin kilitlerse kullanıcı override YOK SAYILIR', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('uni');

    // Kullanıcı büyük yazı seçer.
    s.setUserTextScale(AppTextScale.large);
    expect(s.appearance.scale, AppTextScale.large);

    // Admin yazı boyutunu KİLİTLER (orta) → kullanıcı seçimi yok sayılır.
    s.setAdminTextScale(AppTextScale.small);
    s.setTextScaleLocked(true);
    expect(s.canUserSetTextScale, isFalse);
    expect(s.appearance.scale, AppTextScale.small);

    // Kilit açılınca kullanıcının önceki seçimi geri gelir.
    s.setTextScaleLocked(false);
    expect(s.appearance.scale, AppTextScale.large);
  });

  test('kimlik başına ayrı override — kimlik değişince takas edilir', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501'); // Vedat
    s.selectTenant('uni');
    s.setUserAccent(const Color(0xFF2E7D32));
    expect(s.appearance.accent, const Color(0xFF2E7D32));

    // Başka kimlik (Arda) — override yok, kurum varsayılanı.
    s.logout();
    s.setPendingPhone('+90', '5555555503');
    s.selectTenant('uni');
    expect(s.appearance.accent, const Color(0xFF1F4E8C));
  });
}
