/// Domain models for the GroupConnect member app (mock-data prototype).
///
/// All types are tenant-scoped in practice: they live inside a single
/// [Tenant]'s data island so that cross-tenant isolation (NFR-6) is obvious in
/// the UI. No phone number is stored on any model that reaches a screen —
/// phone numbers are intentionally absent from the directory-facing types
/// (FR-15, FR-24, NFR-5).
library;

import 'package:flutter/material.dart';

import 'enums.dart';

/// A configurable role within a tenant (e.g. academic/student for a
/// university, staff/resident for a housing site). Roles are tenant-scoped and
/// admin-configured (FR-1 vision, FR-55).
class Role {
  const Role({
    required this.id,
    required this.labelTr,
    required this.labelEn,
    required this.isAuthority,
  });

  final String id;
  final String labelTr;
  final String labelEn;

  /// Authority roles (e.g. academics) can be added to contacts directly;
  /// basic roles require approval by default (FR-23).
  final bool isAuthority;

  String label(AppLanguage lang) => lang == AppLanguage.tr ? labelTr : labelEn;
}

/// An organization (multi-tenant). A phone number can belong to several
/// tenants; each runs in a fully isolated context (FR-7, FR-8, NFR-6).
class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    required this.roles,
    required this.defaultVisibility,
    required this.numberSearchEnabled,
    required this.numberSearchLabelTr,
    required this.numberSearchLabelEn,
    this.brandColor = const Color(0xFF3D5AFE),
    this.logoIcon = Icons.business_outlined,
    this.logoAsset,
  });

  final String id;
  final String name;
  final List<Role> roles;

  /// Kurum markası (prototip logo): kurum seçim ekranında logo alanı olarak
  /// gösterilir ve görünüm varsayılan vurgu renginin de kaynağıdır. Gerçek
  /// üründe yüklenmiş bir görsel olacak — burada ikon + renk ile temsil edilir.
  final Color brandColor;
  final IconData logoIcon;

  /// Gerçek logo görselinin asset yolu (ör. `assets/logos/atlas_uni.png`).
  /// null ya da dosya yoksa [logoIcon]'a düşülür (build kırılmaz).
  final String? logoAsset;

  /// Tenant default applied only at member-creation time (FR-17, FR-61).
  final MemberVisibility defaultVisibility;

  /// "Search by number" is a tenant admin preference (FR-14, FR-61).
  final bool numberSearchEnabled;
  final String numberSearchLabelTr;
  final String numberSearchLabelEn;

  Role roleById(String id) => roles.firstWhere((r) => r.id == id);
}

/// A directory member. This is the identity every user is represented by in
/// discovery and contacts. It deliberately has **no phone field** (NFR-5).
class Member {
  Member({
    required this.id,
    required this.fullName,
    this.title = '',
    required this.memberNo,
    required this.department,
    required this.roleId,
    this.course,
    this.groupIds = const [],
    this.visibility = MemberVisibility.visible,
    AddPolicy? addPolicy,
    this.isAuthorityRole = false,
  }) : addPolicy =
           addPolicy ??
           (isAuthorityRole ? AddPolicy.everyone : AddPolicy.approval);

  final String id;

  /// Ad Soyad — ÜNVANSIZ ("Mehmet Kaya"). Ünvan ayrı alandadır ki listeler
  /// ad-soyada göre sıralansın (ünvan başa yazılınca alfabetik sıra bozulur).
  String fullName;

  /// Akademik/mesleki ünvan ("Doç. Dr."); listede ismin ARKASINA yazılır.
  String title;
  String memberNo; // üye/öğrenci no (FR-13)
  String department; // bölüm/birim (FR-13)
  String roleId;
  String? course; // ders — used as a discovery filter (FR-14)
  List<String> groupIds; // group filter (FR-14)

  /// Discovery visibility (FR-16).
  MemberVisibility visibility;

  /// How this member may be added to someone's contacts (FR-22, FR-23, FR-52).
  AddPolicy addPolicy;

  final bool isAuthorityRole;

  /// Deterministic accent colour for the avatar (purely cosmetic).
  Color get avatarColor {
    const palette = [
      Color(0xFF5C6BC0),
      Color(0xFF26A69A),
      Color(0xFFEF6C00),
      Color(0xFF8E24AA),
      Color(0xFF00897B),
      Color(0xFFC2185B),
      Color(0xFF3949AB),
      Color(0xFF43A047),
    ];
    return palette[id.hashCode.abs() % palette.length];
  }

  String get initials {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// A message inside a 1:1 or group thread. Text only — attachments are out of
/// scope and deliberately unmodelled (FR-33, NFR-11).
class Message {
  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.time,
    this.replyToId,
    this.edited = false,
  });

  final String id;
  // Gönderenin MUTLAK üye id'si (ör. 'u_me'). ("me" sabiti kaldırıldı 2026-08-01:
  // kullanıcı değiştirince mesajın doğru tarafta görünmesi için mutlak id şart —
  // "benim mi?" kontrolü artık bakan kişinin td.myId'siyle yapılır.)
  final String senderId;
  String text; // düzenlenebilir (yalnız gönderen — NFR-17)
  final DateTime time;

  /// Yanıtlanan mesajın id'si (aynı dizide) — balonda alıntı olarak gösterilir.
  final String? replyToId;

  /// Gönderen düzenledi — balonda "düzenlendi" etiketi.
  bool edited;
}

/// A group — either admin-managed [GroupType.organized] or member-created
/// private (FR-34..FR-45).
class Group {
  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.memberIds,
    this.managerId,
    this.inviteMessage = '',
    this.logoIcon,
    this.parentGroupId,
    this.isOpen = false,
    this.archived = false,
    this.visibility = GroupVisibility.allMembers,
    this.membersCanWrite = false,
    this.isHierarchyRoot = false,
  });

  final String id;
  String name;
  String description;
  final GroupType type;

  /// Grubun **manager**'ı (FR-90 yeniden düzenlemesi): özel grupta **kurucu**
  /// (FR-37/40 yaşam-döngüsü yetkileri de bunda — arşivle/terk/çıkar), kurumsal
  /// grupta organizasyon admini'nin **atadığı üye** (o grubun üyesi olmalı).
  /// Manager her zaman görür + yazar; [visibility]/[membersCanWrite]
  /// anahtarlarını o çevirir. null yalnız veri-kurulum eksikliğinde olur.
  String? managerId;
  List<String> memberIds;
  String inviteMessage;
  IconData? logoIcon;

  /// FR-90: sohbeti kim görür (manager çevirir). Bkz. [GroupVisibility].
  GroupVisibility visibility;

  /// FR-90: manager DIŞINDAKİ üyeler yazabilir mi (manager çevirir). Varsayılan
  /// false = yalnız manager yazar (herkes okur — duyuru kanalı). true = grubu
  /// görebilen her üye yazar (tartışma). Manager her durumda yazar.
  bool membersCanWrite;

  /// Parent group id for the hierarchy tree (null = top level).
  ///
  /// Only meaningful for **organized** groups, whose hierarchy the tenant admin
  /// defines (Dekanlık → Bölüm → …, see admin `levelLabels`). **Private groups
  /// are always flat** — they never have a parent.
  final String? parentGroupId;

  /// Çocuksuz bir kök düğüm yine de Kurum Yapısı'nda kök olarak sayılsın mı
  /// (ör. alt birimi olmayan bir villa, Bölümlü bir Blok'un yanında)? Var
  /// olan kökler (çocuğu olanlar — ör. Mühendislik Fakültesi) bunu hiç
  /// gerektirmez; yalnız "gerçekten hiyerarşinin bir parçası ama yaprak"
  /// düğümler için. Ayırt edilmesi gereken şey: normal düz kurumsal grup
  /// (ör. bir ders grubu) Kurum Yapısı'nda HİÇ görünmemeli — bu bayrak
  /// olmadan `treeRootGroups` ikisini ayıramazdı.
  final bool isHierarchyRoot;

  /// "Açık" grup: davetsiz katılınabilir (FR-81).
  ///
  /// **Yalnız ÖZEL gruplar için** ve bayrağı **grubu kuran üye** ([managerId])
  /// belirler — kiracı yöneticisi değil. `false` (varsayılan) = kapalı: yalnız
  /// davetle, davet edilmeyene görünmez. `true` = açık: kurumdaki herkes bulur
  /// ve doğrudan katılır.
  ///
  /// **Kurumsal gruplarda anlamsızdır** ve her zaman `false` kalır: kurumsal
  /// üyeliği baştan sona yönetici belirler — davet de, bireysel katılma da,
  /// ayrılma da yoktur (FR-35).
  bool isOpen;

  /// Arşivlenmiş grup: **hiçbir şey yok edilmez.**
  ///
  /// Grubu kuran üye "Grubu Arşivle" der; grup **herkesin** listelerinden
  /// (Gruplar, Sohbetler, Katılabileceklerim) kalkar ama grup da mesaj dizisi
  /// de **durur**. Yalnız kurucusu, Menü → Arşiv'den geri alabilir; geri
  /// alınınca grup mesajlarıyla birlikte eski haline döner.
  ///
  /// Bu, "Grubu Sil"in yerini aldı: üründe **kalıcı silme yoktur**, dolayısıyla
  /// yanlışlıkla geri alınamaz veri kaybı da yoktur ("Emin misin?" sormadan
  /// güvenle uygulanabilmesinin sebebi budur).
  bool archived;

  bool get isOrganized => type == GroupType.organized;
}

/// A contact or group invitation the user can accept/reject (FR-28, FR-38).
class Invitation {
  Invitation({
    required this.id,
    required this.kind,
    required this.direction,
    required this.fromMemberId,
    this.toMemberId,
    this.groupId,
    this.message = '',
    this.status = InviteStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final InviteKind kind;
  final InviteDirection direction;
  final String fromMemberId; // inviter
  final String? toMemberId; // invited member (contact invites)
  final String? groupId; // target group (group invites)
  String message;
  InviteStatus status;

  /// Davetin oluşturulma zamanı — "gönderdiğim davetler" geçmişinde tarih
  /// olarak gösterilir. Runtime'da oluşturulan davetler otomatik `now` alır;
  /// mock açık tarih verir. Kabul/red edilse de değişmez (davet anı).
  final DateTime createdAt;
}
