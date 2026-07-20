import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/models.dart';

/// Tenant-admin-configurable settings — the **prototype surface** for what will
/// live in the real Web Admin panel. Mutable in-memory for the session.
///
/// Mirrors `docs/admin-settings.md`. Editing happens on the Admin Ayarları
/// screen; wiring these into behaviour (esp. §2 group hierarchy) is a follow-up.
class AdminSettings {
  AdminSettings({
    required this.defaultVisibility,
    required this.groupMaxDepth,
    required this.levelLabels,
    required this.roleLabels,
    required this.directRolesByRole,
    required this.accentColor,
    this.accentLocked = false,
    this.textScale = AppTextScale.medium,
    this.textScaleLocked = false,
    this.fontFamily,
    this.fontLocked = false,
  });

  /// §1 Tenant-wide default: [MemberVisibility.visible] = opt-out,
  /// [MemberVisibility.hidden] = opt-in.
  MemberVisibility defaultVisibility;

  /// §2 Group hierarchy depth (1..3). 1 = flat (no sub-groups).
  int groupMaxDepth;

  /// §2 Per-level names (always length 3; only the first [groupMaxDepth] used).
  List<String> levelLabels;

  /// Editable role display names (roleId -> name), set by the admin.
  Map<String, String> roleLabels;

  /// §3+§4'ün YERİNİ ALAN tek kavram — **doğrudan görme/ekleme matrisi**.
  ///
  /// `viewerRoleId -> doğrudan görebildiği hedef roller`. A rolü B'yi
  /// "doğrudan görüyorsa": B'nin üyeleri A'nın **HERKES** sekmesinde listelenir
  /// ve A onları **onaysız, bildirimsiz** rehberine ekler. İşaretli olmayan
  /// çiftlerde ekleme **onay davetiyle** yürür (kişi, paylaşılan grup
  /// listelerinden bulunur — kurum dizininde görünmez).
  Map<String, Set<String>> directRolesByRole;

  /// §5 Görünüm (appearance) — admin varsayılanı + KİLİT (kullanıcı tercihi
  /// 2026-07-19). Kilitliyse herkes bu değeri kullanır; kilitli değilse bu
  /// değer varsayılandır ve her kullanıcı kendine göre değiştirebilir. Üç
  /// eksen: vurgu rengi, yazı boyutu, yazı tipi (null = sistem).
  Color accentColor;
  bool accentLocked;
  AppTextScale textScale;
  bool textScaleLocked;
  String? fontFamily;
  bool fontLocked;

  /// Sensible defaults from the tenant: visibility from the tenant, authority
  /// roles get bulk-add + direct-add. [twoLevel] seeds a 2-level hierarchy
  /// (e.g. Dekanlık → Bölüm) to demonstrate the parametric depth.
  factory AdminSettings.defaults(
    Tenant t, {
    bool twoLevel = false,
    List<String>? levelLabels,
    int? groupMaxDepth,
  }) {
    return AdminSettings(
      defaultVisibility: t.defaultVisibility,
      groupMaxDepth: groupMaxDepth ?? (twoLevel ? 2 : 1),
      levelLabels:
          levelLabels ??
          (twoLevel
              ? ['Dekanlık', 'Bölüm', 'Anabilim Dalı']
              : ['Grup', 'Alt Grup', 'Alt Alt Grup']),
      roleLabels: {for (final r in t.roles) r.id: r.label(AppLanguage.tr)},
      // Varsayılan matris: yetkili roller herkesi görür; temel roller yalnız
      // yetkili rolleri görür (öğrenci → akademisyen; öğrenci → öğrenci onaylı).
      directRolesByRole: {
        for (final r in t.roles)
          r.id:
              r.isAuthority
                  ? {for (final x in t.roles) x.id}
                  : {for (final x in t.roles) if (x.isAuthority) x.id},
      },
      // Görünüm varsayılanı: vurgu rengi kurum markasından; boyut/tip serbest.
      accentColor: t.brandColor,
    );
  }
}
