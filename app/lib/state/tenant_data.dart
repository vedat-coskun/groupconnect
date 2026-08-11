import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/models.dart';

/// All state for a single tenant (organization), kept as an isolated island so
/// that cross-tenant leakage is impossible by construction (FR-7, NFR-6).
///
/// Switching the active organization simply swaps which [TenantData] the UI
/// reads; nothing is shared between two instances.
class TenantData {
  TenantData({
    required this.tenant,
    required this.myId,
    required this.members,
    required this.groups,
    required this.invitations,
    Map<String, List<Message>>? threads,
    List<String>? contactIds,
    Set<String>? favoriteIds,
    Set<String>? favoriteGroupIds,
    Set<String>? blockedIds,
    Map<String, String>? notes,
    Set<String>? dmVisible,
    Map<String, Set<String>>? initialDmVisibleByMyId,
    Set<String>? mutedDms,
    Set<String>? mutedGroupIds,
    Set<String>? passiveIds,
    this.accordionSingle = false,
    this.profileComplete = false,
  }) : threads = threads ?? {},
       contactIds = contactIds ?? [],
       favoriteIds = favoriteIds ?? {},
       favoriteGroupIds = favoriteGroupIds ?? {},
       blockedIds = blockedIds ?? {},
       notes = notes ?? {},
       dmVisible = dmVisible ?? {},
       initialDmVisibleByMyId = initialDmVisibleByMyId ?? const {},
       mutedDms = mutedDms ?? {},
       mutedGroupIds = mutedGroupIds ?? {},
       passiveIds = passiveIds ?? {};

  final Tenant tenant;

  /// The current user's own [Member] id within this tenant. Mutable so the
  /// prototype can switch the logged-in identity by phone (MockData.identities).
  String myId;

  /// Directory: every member the admin provisioned, including [myId]
  /// (FR-12). Always populated.
  final Map<String, Member> members;

  final List<Group> groups;
  final List<Invitation> invitations;


  /// Message store, keyed by thread id (`dm:<memberId>` / `grp:<groupId>`).
  final Map<String, List<Message>> threads;

  /// Personal contacts / rehber (AKTİF). Starts **empty** for the current user
  /// (FR-20); grows as they add people through discovery.
  final List<String> contactIds;

  /// PASİF bağlantılar (kullanıcı hükmü 2026-08-02): bana gelen bir daveti
  /// **tek yönlü** kabul ettiğim (onayladım ama karşıyı AKTİF rehberime
  /// eklemediğim) kişiler. Aktif rehberde DEĞİL; Rehberim'in "+ Pasif"
  /// görünümünde çıkar. Kimlik başına saklanır (blob 'p').
  final Set<String> passiveIds;

  // NOT: Aşağıdaki alanların TÜMÜ **bakan kimliğe** aittir ve (kurum + kimlik)
  // başına saklanıp kimlik değişiminde takas edilir (AppState._applyUser).
  // Kimlikten bağımsız tek kişisel-olmayan durum: members/groups/threads
  // (paylaşılan "sunucu" verisi) ve admin ayarları.
  final Set<String> favoriteIds; // FR-54
  final Set<String> favoriteGroupIds; // favori gruplar
  final Set<String> blockedIds; // FR-18, FR-53
  final Map<String, String> notes; // FR-24: rehber owner's notes
  final Set<String> dmVisible; // 1:1 threads surfaced in the chat list

  /// Mock seed: **kimlik (myId) başına** başlangıç DM görünürlüğü. Bir kimliğin
  /// KAYITLI blob'u yoksa (ilk giriş) [AppState._applyUser] o kimliğin seed'ine
  /// döner — prototip ilk açılışta dolu bir HEPSİ göstersin. Kimlik-başına
  /// olduğu için sızıntı olmaz: seed'i olmayan kimlik boş kümeye düşer (Vedat'ın
  /// yazışmaları Can/Suden'e yüzmez).
  final Map<String, Set<String>> initialDmVisibleByMyId;
  final Set<String> mutedDms; // FR-49 for 1:1 threads
  final Set<String> mutedGroupIds; // FR-49 for groups — kişisel, grup-üstü değil

  /// Görünüm (appearance) KİŞİSEL override'ları — kimlik başına saklanır
  /// (kullanıcı tercihi 2026-07-19). null = kurum varsayılanını kullan. Admin
  /// ilgili ekseni KİLİTLEMİŞSE bu değerler yok sayılır (etkin değer app_state).
  Color? userAccent;
  AppTextScale? userTextScale;
  String? userFont;

  /// TEKLİ AKORDİYON tercihi (kişisel, kimlik başına — kullanıcı 2026-08-06):
  /// true ise akordiyonlu sayfalarda bir bölüm açılınca kardeşleri kapanır;
  /// false (varsayılan) = çoklu (birden çok bölüm açık kalabilir). blob 'as'.
  bool accordionSingle;

  /// False until the first-login profile setup is confirmed (FR-9).
  bool profileComplete;

  Member get me => members[myId]!;
  Member? member(String id) => members[id];
  Group? group(String id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }
}
