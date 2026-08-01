import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'admin_settings.dart';
import 'mock_data.dart';
import 'tenant_data.dart';

/// Top-level navigation phase of the app.
enum AppPhase { splash, onboarding, auth, tenantSelect, profileSetup, home }

/// Outcome of attempting to add someone to contacts (FR-22, FR-23).
enum AddResult { added, invited, already }

/// A row in the unified chat list (groups + 1:1). Purely a view model.
class ChatSummary {
  ChatSummary({
    required this.threadId,
    required this.title,
    required this.isGroup,
    required this.muted,
    this.member,
    this.group,
    this.lastMessageText,
    this.lastMessageTime,
  });

  final String threadId;
  final String title;
  final bool isGroup;
  final bool muted;
  final Member? member;
  final Group? group;

  /// Dizideki son mesajın metni ve zamanı — **yalnız Sohbetler → "HEPSİ"**
  /// bölümü kullanır (önizleme + saat + son-aktivite sırası). FR-100'ün
  /// geri alınması (kurum sahibi hükmü 2026-07-22): kategori bölümleri hâlâ
  /// içerik taşımaz; HEPSİ bir gelen-kutusu olarak önizleme gösterir. Mesajsız
  /// dizide ikisi de null (HEPSİ zaten yalnız içi-dolu sohbetleri listeler).
  final String? lastMessageText;
  final DateTime? lastMessageTime;
}

/// The single source of truth for the prototype. A [ChangeNotifier] so the
/// [AppScope] can rebuild listeners on any mutation. All data is in memory —
/// there is no backend, network or encryption (this is a UI prototype).
class AppState extends ChangeNotifier {
  AppState()
    : _tenants = MockData.tenants(),
      _data = MockData.build();

  final List<Tenant> _tenants;
  final Map<String, TenantData> _data;

  /// Prototype admin-panel settings, one per tenant (Web Admin surface). Uni
  /// seeds a 2-level hierarchy (Dekanlık → Bölüm) to demo parametric depth.
  late final Map<String, AdminSettings> _admin = {
    for (final t in _tenants)
      t.id: AdminSettings.defaults(
        t,
        twoLevel: t.id == MockData.uniId || t.id == MockData.siteId,
        levelLabels:
            t.id == MockData.siteId ? ['Kategori', 'Blok', 'Daire'] : null,
        // Site: Kategori(İdari/Sahip/Sakin) → Blok/Villa → Daire = 3 seviye.
        groupMaxDepth: t.id == MockData.siteId ? 3 : null,
      ),
  };

  AppLanguage _language = AppLanguage.tr;
  AppPhase _phase = AppPhase.splash;
  bool _onboardingSeen = false;
  String _countryCode = '+90';
  String _phone = '';
  // Prototip: telefonun son haneleri kimliği belirler (MockData.identities).
  MockIdentity _identity = MockData.identityForPhone('');
  String? _activeTenantId;
  // "Tercihimi Hatırla": set ise sonraki girişte seçim ekranı atlanır (FR-87).
  String? _rememberedTenantId;

  // ---- Global getters -----------------------------------------------------
  AppLanguage get language => _language;
  AppPhase get phase => _phase;
  bool get onboardingSeen => _onboardingSeen;
  String get countryCode => _countryCode;
  String get phone => _phone;
  String get displayPhone => '$_countryCode $_phone';

  /// Tenants the signed-in phone belongs to (FR-7).
  List<Tenant> get loginTenants =>
      _identity.tenantIds.map(tenantById).toList(growable: false);
  bool get isMultiTenant => _identity.tenantIds.length > 1;
  bool get hasRememberedTenant => _rememberedTenantId != null;

  Tenant tenantById(String id) => _tenants.firstWhere((t) => t.id == id);

  Tenant? get activeTenant =>
      _activeTenantId == null ? null : tenantById(_activeTenantId!);

  /// Active tenant's data island. Only valid once signed in.
  TenantData get td => _data[_activeTenantId]!;
  Member get me => td.me;
  AdminSettings get adminSettings => _admin[_activeTenantId]!;

  // ---- Görünüm (appearance) — admin-parametrik + kullanıcı override ---------
  // Etkin değer: admin ekseni KİLİTLEDİYSE admin değeri; değilse kullanıcının
  // kendi seçimi (yoksa admin varsayılanı). Tenant seçilmeden fallback döner.

  /// Etkin görünüm — MaterialApp teması bundan kurulur (reaktif, app.dart).
  Appearance get appearance {
    final id = _activeTenantId;
    if (id == null) return Appearance.fallback;
    final a = _admin[id]!;
    final d = _data[id]!;
    return Appearance(
      accent: a.accentLocked ? a.accentColor : (d.userAccent ?? a.accentColor),
      scale: a.textScaleLocked ? a.textScale : (d.userTextScale ?? a.textScale),
      fontFamily:
          a.fontLocked ? a.fontFamily : (d.userFont ?? a.fontFamily),
    );
  }

  /// Bir görünüm ekseni kullanıcı tarafından değiştirilebilir mi (kilitli değil)?
  bool get canUserSetAccent => !adminSettings.accentLocked;
  bool get canUserSetTextScale => !adminSettings.textScaleLocked;
  bool get canUserSetFont => !adminSettings.fontLocked;

  // Admin (Web Admin prototipi) — varsayılan + kilit çevirir.
  void setAdminAccent(Color c) {
    adminSettings.accentColor = c;
    notifyListeners();
  }

  void setAdminTextScale(AppTextScale s) {
    adminSettings.textScale = s;
    notifyListeners();
  }

  void setAdminFont(String? family) {
    adminSettings.fontFamily = family;
    notifyListeners();
  }

  void setAccentLocked(bool v) {
    adminSettings.accentLocked = v;
    notifyListeners();
  }

  void setTextScaleLocked(bool v) {
    adminSettings.textScaleLocked = v;
    notifyListeners();
  }

  void setFontLocked(bool v) {
    adminSettings.fontLocked = v;
    notifyListeners();
  }

  // Kullanıcı override — kimlik başına saklanır (null = kurum varsayılanı).
  void setUserAccent(Color? c) {
    td.userAccent = c;
    _saveUser();
    notifyListeners();
  }

  void setUserTextScale(AppTextScale? s) {
    td.userTextScale = s;
    _saveUser();
    notifyListeners();
  }

  void setUserFont(String? family) {
    td.userFont = family;
    _saveUser();
    notifyListeners();
  }

  // ---- Language -----------------------------------------------------------
  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }

  // ---- Onboarding / auth flow (FR-1..FR-9) --------------------------------
  void advanceFromSplash() {
    _phase = _onboardingSeen ? AppPhase.auth : AppPhase.onboarding;
    notifyListeners();
  }

  void finishOnboarding() {
    _onboardingSeen = true;
    _phase = AppPhase.auth;
    notifyListeners();
  }

  /// GELİŞTİRME KISAYOLU (yalnız debug — [kDevAutoLogin]): onboarding/telefon/
  /// OTP/kurum akışını atlayıp doğrudan verilen kimlik + kurumla ana ekrana
  /// düşer. Normal giriş yolunu (setPendingPhone → selectTenant) kullanır, yani
  /// tüm state doğru kurulur; sadece ara ekranları es geçer.
  void devAutoLogin({
    String phone = '5555555501',
    String tenantId = 'uni',
  }) {
    _onboardingSeen = true;
    setPendingPhone('+90', phone);
    selectTenant(tenantId);
  }

  /// GELİŞTİRME KISAYOLU (yalnız debug — alt çubuktaki "Demo" sekmesi): kimliği
  /// telefon/OTP olmadan ANINDA değiştirir. Paylaşılan veri (`_data`: mesajlar/
  /// gruplar) tek bellekte durduğundan, bir kullanıcı mesaj atıp diğerine
  /// geçince o mesaj görünür — iki-kişilik akışları tek simülatörde test etmek
  /// için. Mevcut kimliğin kişisel durumu önce saklanır ([_saveUser]), sonra
  /// yeni kimlik yüklenir ([_applyUser]). Kimlik zaten aktifse hiçbir şey yapmaz.
  void switchDemoUser(String phone, {String tenantId = 'uni'}) {
    if (phone == _phone && _phase == AppPhase.home) return;
    if (_activeTenantId != null) _saveUser();
    setPendingPhone('+90', phone);
    selectTenant(tenantId);
  }

  void setPendingPhone(String countryCode, String phone) {
    _countryCode = countryCode;
    _phone = phone;
    // Telefona göre kimliği çöz (prototip çok-kullanıcı — MockData.identities).
    _identity = MockData.identityForPhone(phone);
    notifyListeners();
  }

  /// Called once the (mock) OTP has been entered. Any 6-digit code is accepted
  /// (FR-6, prototype). Returns true when a tenant-selection step is required.
  bool verifyOtp() {
    if (!isMultiTenant) {
      selectTenant(_identity.tenantIds.first);
      return false;
    }
    // "Hatırla" seçiliyse (önceki girişten) kurum seçimini atla (FR-87).
    if (_rememberedTenantId != null &&
        _identity.tenantIds.contains(_rememberedTenantId)) {
      selectTenant(_rememberedTenantId!);
      return false;
    }
    return true;
  }

  /// Enter a tenant context. Routes to first-login profile setup when that
  /// tenant's profile has not been completed yet (FR-9).
  void selectTenant(String tenantId, {bool remember = false}) {
    _activeTenantId = tenantId;
    // Kimliğe göre bu tenant'taki "ben" üyesini ata (prototip çok-kullanıcı).
    final mine = _identity.myIdByTenant[tenantId];
    if (mine != null) _data[tenantId]!.myId = mine;
    // Bu kimliğin kendi rehberini/favorilerini yükle (kişiden bağımsız değil).
    _applyUser(tenantId, _data[tenantId]!.myId);
    // "Tercihimi Hatırla" iki yönlü olmalı: işareti kaldırmak, daha önce
    // hatırlanan kurumu da İPTAL eder. Yalnız `if (remember)` yazılırsa kutunun
    // işaretini kaldırmak sessizce hiçbir şey yapmaz ve kullanıcı sonraki
    // girişte eski kuruma düşer (FR-87).
    _rememberedTenantId = remember ? tenantId : null;
    // Girişte bekleyen davetleri matrisle uzlaştır (fosil onaylar kalkar).
    _reconcileMatrixInvites();
    _phase = td.profileComplete ? AppPhase.home : AppPhase.profileSetup;
    notifyListeners();
  }

  void completeProfileSetup({
    required String fullName,
    required String memberNo,
    required String department,
    required String roleId,
  }) {
    final m = me;
    m.fullName = fullName.trim().isEmpty ? m.fullName : fullName.trim();
    m.memberNo = memberNo.trim();
    m.department = department.trim();
    m.roleId = roleId;
    td.profileComplete = true;
    _phase = AppPhase.home;
    notifyListeners();
  }

  void logout() {
    _activeTenantId = null;
    _phone = '';
    _identity = MockData.identityForPhone('');
    _everyoneExpandedRoles.clear(); // accordion durumu oturum boyu (logout=sıfır)
    _expandedTreeGroups.clear();
    _expandedTreeRoles.clear();
    _expandedChatSections.clear();
    _phase = AppPhase.auth;
    notifyListeners();
  }

  // ---- Kişiler → Herkes accordion (oturum boyu, diske YAZILMAZ) -----------
  // Rol bölümleri VARSAYILAN KAPALI başlar (bu set boş); bir rol yalnız bu
  // sette ise açıktır. Durum widget'ta değil burada durduğu için sekme
  // değişince/geri gelince sıfırlanmaz — yalnız logout temizler (kullanıcı
  // tercihi 2026-07-19).
  final Set<String> _everyoneExpandedRoles = {};
  bool isEveryoneRoleExpanded(String label) =>
      _everyoneExpandedRoles.contains(label);
  void toggleEveryoneRole(String label) {
    if (!_everyoneExpandedRoles.remove(label)) {
      _everyoneExpandedRoles.add(label);
    }
    notifyListeners();
  }

  // ---- Kurum Yapısı (Kurumsal) ağacı — yerinde akordiyon, oturum boyu -------
  // Fakülte→Bölüm→üyeler tek ekranda açılıp kapanır (kullanıcı tercihi
  // 2026-07-19). VARSAYILAN KAPALI (set boş); bir grup yalnız bu sette ise
  // açıktır. Durum burada durduğu için sekme/gezinme sıfırlamaz — logout
  // temizler.
  final Set<String> _expandedTreeGroups = {};
  bool isTreeGroupExpanded(String groupId) =>
      _expandedTreeGroups.contains(groupId);
  void toggleTreeGroup(String groupId) {
    if (!_expandedTreeGroups.remove(groupId)) {
      _expandedTreeGroups.add(groupId);
    }
    notifyListeners();
  }

  // Ağaç yaprağındaki üye ROL bölümleri de accordion — bölüme özgü (groupId +
  // rol etiketi anahtarı). Varsayılan kapalı, logout'a kadar kalıcı.
  final Set<String> _expandedTreeRoles = {};
  bool isTreeRoleExpanded(String groupId, String label) =>
      _expandedTreeRoles.contains('$groupId::$label');
  void toggleTreeRole(String groupId, String label) {
    final key = '$groupId::$label';
    if (!_expandedTreeRoles.remove(key)) _expandedTreeRoles.add(key);
    notifyListeners();
  }

  // Sohbetler'in üç KATEGORİSİ (Kişisel/Kurumsal/Özel) accordion — eski filtre
  // çipleri yerine (kullanıcı tercihi 2026-07-19). Varsayılan üçü de KAPALI,
  // logout'a kadar kalıcı.
  final Set<String> _expandedChatSections = {};
  bool isChatSectionExpanded(String key) =>
      _expandedChatSections.contains(key);
  void toggleChatSection(String key) {
    if (!_expandedChatSections.remove(key)) _expandedChatSections.add(key);
    notifyListeners();
  }

  /// Switch active organization from inside the app (FR-8). Re-runs first-login
  /// setup if the target tenant profile is incomplete.
  void switchTenant(String tenantId) {
    if (tenantId == _activeTenantId) return;
    // Menü'den değiştirilir; "Hatırla" aktifse hatırlanan kurumu da güncelle.
    selectTenant(tenantId, remember: _rememberedTenantId != null);
  }

  /// Menü → Kurum Değiştir: baştaki kurum-seçim ekranına (TenantSelectScreen)
  /// dön. Seçim sonrası uygulamaya yeni girmiş gibi ana ekrana geçilir —
  /// menüye dönülmez. Yalnız çok-kuruma üye kimlikler için anlamlı.
  void startTenantSwitch() {
    if (!isMultiTenant) return;
    _phase = AppPhase.tenantSelect;
    notifyListeners();
  }

  // ---- Persistence (rehber + favoriler; KİMLİK başına) --------------------
  // Seed veri (üyeler, gruplar, admin ayarları) kurum bazlı ve her açılışta
  // taze. Kullanıcının kendi eklediği veri (rehber, favoriler) ise
  // **(kurum + kimlik)** başına diske yazılır — böylece 1/2/3 ile giren herkes
  // kendi rehberini görür; yalnız admin ayarları kişiden bağımsızdır.
  static String _userKey(String tenantId, String myId) =>
      'gc_user_${tenantId}_$myId';

  // Diskteki kullanıcı blob'larının önbelleği, "tenantId::myId" anahtarlı.
  final Map<String, Map<String, dynamic>> _userCache = {};

  /// Load every identity's persisted user data into the cache (once, at startup
  /// before login). Best-effort.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final identity in MockData.identities) {
        identity.myIdByTenant.forEach((tenantId, myId) {
          final raw = prefs.getString(_userKey(tenantId, myId));
          if (raw != null) {
            _userCache['$tenantId::$myId'] =
                jsonDecode(raw) as Map<String, dynamic>;
          }
        });
      }
    } catch (_) {
      // Best-effort read.
    }
  }

  /// Apply the cached user blob for (tenant, identity) into the tenant island.
  ///
  /// KİMLİK KAPSAMI: kişisel durumun TAMAMI takas edilir — rehber, favoriler,
  /// engellenenler, notlar, 1:1 görünürlüğü ve sessize almalar. Blob yoksa
  /// hepsi boşa döner; bir kimliğin kişisel verisi diğerine asla sızmaz.
  void _applyUser(String tenantId, String myId) {
    final d = _data[tenantId]!;
    final blob = _userCache['$tenantId::$myId'] ?? const <String, dynamic>{};
    d.contactIds
      ..clear()
      ..addAll(
        ((blob['c'] as List?)?.cast<String>() ?? const [])
            .where((id) => d.members.containsKey(id)),
      );
    d.favoriteIds
      ..clear()
      ..addAll((blob['f'] as List?)?.cast<String>() ?? const []);
    d.favoriteGroupIds
      ..clear()
      ..addAll((blob['fg'] as List?)?.cast<String>() ?? const []);
    d.blockedIds
      ..clear()
      ..addAll((blob['b'] as List?)?.cast<String>() ?? const []);
    d.notes
      ..clear()
      ..addAll(
        ((blob['n'] as Map?)?.cast<String, String>()) ?? const {},
      );
    // Kayıtlı blob'da 'dv' varsa onu kullan; YOKSA (ilk giriş) BU KİMLİĞİN mock
    // seed'ine dön — prototip ilk açılışta dolu bir HEPSİ göstersin. Kimlik-
    // başına seed olduğundan sızıntı olmaz (seed'i olmayan kimlik boşa düşer).
    d.dmVisible
      ..clear()
      ..addAll(
        blob.containsKey('dv')
            ? (blob['dv'] as List).cast<String>()
            : (d.initialDmVisibleByMyId[myId] ?? const <String>{}),
      );
    d.mutedDms
      ..clear()
      ..addAll((blob['md'] as List?)?.cast<String>() ?? const []);
    d.mutedGroupIds
      ..clear()
      ..addAll((blob['mg'] as List?)?.cast<String>() ?? const []);
    // Görünüm override'ları (kimlik başına). Yoksa null = kurum varsayılanı.
    d.userAccent =
        blob['ua'] is int ? Color(blob['ua'] as int) : null;
    d.userTextScale = switch (blob['us']) {
      'small' => AppTextScale.small,
      'medium' => AppTextScale.medium,
      'large' => AppTextScale.large,
      _ => null,
    };
    d.userFont = blob['uf'] as String?;
  }

  /// Fire-and-forget save of the active (tenant, identity) user data.
  void _saveUser() {
    final id = _activeTenantId;
    if (id == null) return;
    final d = _data[id]!;
    final blob = <String, dynamic>{
      'c': List<String>.from(d.contactIds),
      'f': d.favoriteIds.toList(),
      'fg': d.favoriteGroupIds.toList(),
      'b': d.blockedIds.toList(),
      'n': Map<String, String>.from(d.notes),
      'dv': d.dmVisible.toList(),
      'md': d.mutedDms.toList(),
      'mg': d.mutedGroupIds.toList(),
      if (d.userAccent != null) 'ua': d.userAccent!.toARGB32(),
      if (d.userTextScale != null) 'us': d.userTextScale!.name,
      if (d.userFont != null) 'uf': d.userFont,
    };
    _userCache['$id::${d.myId}'] = blob;
    _persist(id, d.myId, blob);
  }

  Future<void> _persist(
    String tenantId,
    String myId,
    Map<String, dynamic> blob,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey(tenantId, myId), jsonEncode(blob));
    } catch (_) {
      // Best-effort save.
    }
  }

  // ---- Roles --------------------------------------------------------------
  Role roleOf(Member m) => activeTenant!.roleById(m.roleId);
  bool isAuthority(Member m) => roleOf(m).isAuthority;
  List<Role> get tenantRoles => activeTenant!.roles;

  /// Display name for a role, honouring the admin's edited label (Adım 2 —
  /// admin ayarları uygulamaya anında yansır).
  String roleName(Role r) => adminSettings.roleLabels[r.id] ?? r.label(language);

  // ---- Admin settings (prototype surface for the Web Admin panel) ---------
  void setDefaultVisibility(MemberVisibility v) {
    adminSettings.defaultVisibility = v;
    notifyListeners();
  }

  void setGroupMaxDepth(int depth) {
    // Kullanım-öncesi kilit: kullanımdaki en derin seviyenin altına inilemez.
    adminSettings.groupMaxDepth = depth.clamp(usedGroupDepth, 3);
    notifyListeners();
  }

  void setLevelLabel(int index, String label) {
    if (index < 0 || index >= adminSettings.levelLabels.length) return;
    adminSettings.levelLabels[index] = label;
    notifyListeners();
  }

  void setRoleLabel(String roleId, String label) {
    adminSettings.roleLabels[roleId] = label;
    notifyListeners();
  }

  /// Matris hücresini çevir: [viewerRoleId] rolü [targetRoleId] rolünü
  /// doğrudan görsün mü? (Admin Ayarları — görme = sormadan ekleme.)
  void toggleDirectRole(String viewerRoleId, String targetRoleId) {
    final set = adminSettings.directRolesByRole.putIfAbsent(
      viewerRoleId,
      () => <String>{},
    );
    if (!set.remove(targetRoleId)) set.add(targetRoleId);
    // 🟢 canlı ayar: matrisin açtığı çiftlerde bekleyen onaylar geçersizleşir.
    _reconcileMatrixInvites();
    notifyListeners();
  }

  /// Bekleyen KİŞİ davetlerini matrisle uzlaştır (kurum sahibi hükmü —
  /// "admin ayarlarından dolayı artık doğrudan ekleyebiliyor; bu bilgiyi
  /// kaldır"). Matrisin artık DOĞRUDAN gördüğü bir çift arasında onay süreci
  /// anlamsızdır:
  /// - BENİM gönderdiğim bekleyen istek → doğrudan eklemeye dönüşür (kişi
  ///   rehberime girer, davet kaydı kalkar).
  /// - BANA gelen bekleyen istek → geçersiz (void) olur ve kaldırılır; gönderen
  ///   kendi oturumunda aynı kuralla doğrudan eklemeye kavuşur.
  /// Girişte (selectTenant) ve admin matrisi değiştiğinde çalışır. Kapanan
  /// (matristen çıkarılan) çiftlerde geçmişe dokunulmaz — 🟢: geçmiş durur.
  void _reconcileMatrixInvites() {
    final removed = <Invitation>[];
    for (final i in td.invitations) {
      if (i.kind != InviteKind.contact) continue;
      if (i.status != InviteStatus.pending) continue;
      final from = td.member(i.fromMemberId);
      final to = i.toMemberId == null ? null : td.member(i.toMemberId!);
      if (from == null || to == null) continue;
      if (!canSeeDirectly(from.roleId, to.roleId)) continue;
      if (i.fromMemberId == td.myId && !td.contactIds.contains(i.toMemberId)) {
        td.contactIds.add(i.toMemberId!);
      }
      removed.add(i);
    }
    if (removed.isEmpty) return;
    td.invitations.removeWhere(removed.contains);
    _saveUser();
  }

  /// Matris: bakanın rolü, hedefin rolünü doğrudan görüyor mu?
  bool canSeeDirectly(String viewerRoleId, String targetRoleId) =>
      adminSettings.directRolesByRole[viewerRoleId]?.contains(targetRoleId) ??
      false;

  /// HERKES sekmesi: erişebildiğim herkes. Matris bir **engel değil,
  /// varsayılandır** (kurum sahibi hükmü 2026-08-01): matris DOĞRUDAN
  /// görüyorsa kişi bireysel ayarından bağımsız her zaman görünür; matris
  /// görmüyorsa da ENGELLİ değildir — kişi kendini "Görünür" tuttuğu sürece
  /// listede kalır (yalnız ekleme onaya bağlıdır). Tek dışlanan: matris-dışı
  /// VE kendini "Görünmez" yapan. (Aynı koşulu [directorySearch] da kullanır.)
  List<Member> get everyoneVisible =>
      td.members.values
          .where(
            (m) =>
                m.id != td.myId &&
                !td.blockedIds.contains(m.id) &&
                !(!canSeeDirectly(me.roleId, m.roleId) &&
                    m.visibility == MemberVisibility.hidden),
          )
          .toList();

  // ---- Directory & discovery (FR-12..FR-19) -------------------------------
  List<Member> directorySearch({
    String query = '',
    String? roleId,
    String? department,
    String? course,
    String? groupId,
    bool sortByNumber = false,
  }) {
    final q = query.trim().toLowerCase();
    final results =
        td.members.values.where((m) {
          if (m.id == td.myId) return false;
          // Matris + gizlenme (kurum sahibi hükmü): matris DOĞRUDAN görüyorsa
          // kişi her durumda görünür (bireysel gizlenme işlemez). Matris-dışı
          // çiftlerde kişi aramada KALIR ve ancak ONAYLI eklenebilir — ama
          // kendini GİZLEDİYSE bu yoldan da çıkar.
          if (!canSeeDirectly(me.roleId, m.roleId) &&
              m.visibility == MemberVisibility.hidden) {
            return false;
          }
          if (td.blockedIds.contains(m.id)) return false; // FR-18
          if (q.isNotEmpty) {
            final hay =
                '${m.fullName} ${m.memberNo} ${m.department}'.toLowerCase();
            if (!hay.contains(q)) return false; // FR-13
          }
          if (roleId != null && m.roleId != roleId) return false; // FR-14
          if (department != null && m.department != department) return false;
          if (course != null && m.course != course) return false;
          // Grup üyeliği alt-ağaç birleşimine göre (FR-71): Fakülte seçilince
          // bölümlerinin üyeleri de eşleşir (yaprak-dışı düğümde memberIds boş).
          if (groupId != null) {
            final grp = td.group(groupId);
            if (grp == null || !aggregateMemberIdsOf(grp).contains(m.id)) {
              return false;
            }
          }
          return true;
        }).toList();

    results.sort(
      (a, b) =>
          sortByNumber
              ? a.memberNo.compareTo(b.memberNo)
              : a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return results;
  }

  List<String> get directoryDepartments {
    final set = <String>{};
    for (final m in td.members.values) {
      if (m.id != td.myId) set.add(m.department);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get directoryCourses {
    final set = <String>{};
    for (final m in td.members.values) {
      if (m.course != null) set.add(m.course!);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Group> get filterGroups => td.groups;

  // ---- Personal contacts (FR-20..FR-27) -----------------------------------
  bool isContact(String id) => td.contactIds.contains(id);
  bool isFavorite(String id) => td.favoriteIds.contains(id);
  bool isBlocked(String id) => td.blockedIds.contains(id);

  List<Member> get contacts {
    final list =
        td.contactIds
            .where((id) => id != td.myId) // kendini rehberde gösterme
            .map((id) => td.member(id))
            .whereType<Member>()
            .toList();
    list.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return list;
  }

  List<Member> get favorites =>
      contacts.where((m) => td.favoriteIds.contains(m.id)).toList();

  List<Member> get blockedMembers =>
      td.blockedIds.map((id) => td.member(id)).whereType<Member>().toList();

  /// Adds [id] to contacts, honouring their add-policy (FR-22, FR-23).
  ///
  /// Authority roles (e.g. academics) are added directly; basic roles (e.g.
  /// students) get an outgoing approval invitation carrying [message].
  AddResult addContact(String id, {String message = ''}) {
    if (isContact(id)) return AddResult.already;
    final m = td.member(id);
    if (m == null) return AddResult.already;
    // Karar merdiveni (kurum sahibi hükmü):
    // 1) Matris rolümü hedefin rolünü DOĞRUDAN görüyorsa → onaysız (kişisel
    //    izin işlemez — FR-64).
    // 2) Matris görmüyorsa kişisel izin konuşur: hedef "Herkes" seçtiyse →
    //    onaysız; "Onayladıklarım" (varsayılan) ise → onay daveti (DAVETLER).
    if (canSeeDirectly(me.roleId, m.roleId) ||
        m.addPolicy == AddPolicy.everyone) {
      td.contactIds.add(id);
      _saveUser();
      notifyListeners();
      return AddResult.added;
    }
    // Approval required: record an outgoing invitation (FR-22).
    final exists = td.invitations.any(
      (i) =>
          i.kind == InviteKind.contact &&
          i.fromMemberId == td.myId &&
          i.toMemberId == id &&
          i.status == InviteStatus.pending,
    );
    if (!exists) {
      td.invitations.add(
        Invitation(
          id: 'out_${DateTime.now().microsecondsSinceEpoch}',
          kind: InviteKind.contact,
          direction: InviteDirection.outgoing,
          fromMemberId: td.myId,
          toMemberId: id,
          message: message.trim(),
        ),
      );
    }
    notifyListeners();
    return AddResult.invited;
  }

  /// Directly add someone who already added me (FR-27, mutual consent).
  void addContactDirect(String id) {
    if (!isContact(id)) td.contactIds.add(id);
    _saveUser();
    notifyListeners();
  }

  /// DAVETLER → "Onaylananlar" (kurum sahibi hükmü): onay süreciyle kurulmuş
  /// (accepted) kişi bağı olan ama şu an REHBERDE OLMAYAN kişiler. Rehberim'den
  /// silinen onaylı kişi buraya düşer — verilmiş rıza kaybolmaz, tek dokunuşla
  /// yeniden eklenir. Doğrudan (matrisle) eklenmiş kişinin davet kaydı hiç
  /// olmadığından o tamamen silinir, burada görünmez.
  List<Member> get approvedNotInContacts {
    final ids = <String>{};
    for (final i in td.invitations) {
      if (i.kind != InviteKind.contact) continue;
      if (i.status != InviteStatus.accepted) continue;
      final other =
          i.fromMemberId == td.myId
              ? i.toMemberId
              : (i.toMemberId == td.myId ? i.fromMemberId : null);
      if (other == null) continue;
      if (td.contactIds.contains(other)) continue;
      if (td.blockedIds.contains(other)) continue;
      ids.add(other);
    }
    final list = ids.map((id) => td.member(id)).whereType<Member>().toList();
    list.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return list;
  }

  /// "Rehberdeymiş gibi" davranılacak kişi (kurum sahibi hükmü): rehberde
  /// OLAN ya da rolümün matriste DOĞRUDAN gördüğü (HERKES'te listelenen) kişi.
  /// Matris görüyorsa "henüz rehberinde değil" ayrımı anlamsızdır — kişi zaten
  /// tek dokunuşla onaysız eklenebilir; sohbet/detay ikinci sınıf davranmaz.
  bool treatAsContact(String memberId) {
    if (td.contactIds.contains(memberId)) return true;
    final m = td.member(memberId);
    if (m == null) return false;
    return canSeeDirectly(me.roleId, m.roleId);
  }

  void removeContact(String id) {
    td.contactIds.remove(id);
    td.favoriteIds.remove(id);
    td.notes.remove(id);
    _saveUser();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (td.favoriteIds.contains(id)) {
      td.favoriteIds.remove(id);
    } else {
      td.favoriteIds.add(id);
    }
    _saveUser();
    notifyListeners();
  }

  bool isFavoriteGroup(String id) => td.favoriteGroupIds.contains(id);
  void toggleFavoriteGroup(String id) {
    if (!td.favoriteGroupIds.remove(id)) td.favoriteGroupIds.add(id);
    _saveUser();
    notifyListeners();
  }

  String noteFor(String id) => td.notes[id] ?? '';
  void setNote(String id, String text) {
    if (text.trim().isEmpty) {
      td.notes.remove(id);
    } else {
      td.notes[id] = text.trim();
    }
    _saveUser();
    notifyListeners();
  }

  void block(String id) {
    td.blockedIds.add(id);
    td.contactIds.remove(id);
    td.favoriteIds.remove(id);
    _saveUser();
    notifyListeners();
  }

  void unblock(String id) {
    td.blockedIds.remove(id);
    _saveUser();
    notifyListeners();
  }

  // ---- Invitations (FR-28) ------------------------------------------------
  // "Davetiyeler" ekranı yalnız **kişi davetlerini** kapsar; grup davetleri
  // "Katılabileceklerim"e aittir. Yön **bakan kişiye görelidir**: bana
  // adreslenmiş (toMemberId == myId) bekleyen kişi daveti "gelen", benden giden
  // (fromMemberId == myId) "giden"dir — mutlak `direction` alanına bakılmaz.
  List<Invitation> get incomingInvites =>
      td.invitations
          .where(
            (i) =>
                i.kind == InviteKind.contact &&
                i.status == InviteStatus.pending &&
                i.toMemberId == td.myId,
          )
          .toList();

  /// Gönderdiğim REHBER (kişi) davetlerinin ÇÖZÜLMEMİŞ/BAŞARISIZ geçmişi —
  /// **Beklemede + Reddedildi**, en yeni üstte. "Davetler → Gönderdiğim" bölümü
  /// bunu gösterir (durum + tarih). **Kabul edilenler KAPSAM DIŞI** (kullanıcı
  /// hükmü 2026-08-01): kabul = başarı → kişi zaten Rehberim'de ya da (rehberden
  /// çıkmışsa) "Kabul Edilenler"de görünür; burada tekrar göstermek çift kayıt
  /// olurdu. Grup davetleri de kapsam dışı (onlar Gruplar tarafına aittir).
  /// [id]'ye gönderdiğim BEKLEYEN rehber daveti (varsa) — Herkes listesinde
  /// "beklemede" durumunu göstermek/iptal için. Yoksa null.
  Invitation? pendingContactInviteTo(String id) {
    for (final i in td.invitations) {
      if (i.kind == InviteKind.contact &&
          i.direction == InviteDirection.outgoing &&
          i.fromMemberId == td.myId &&
          i.toMemberId == id &&
          i.status == InviteStatus.pending) {
        return i;
      }
    }
    return null;
  }

  List<Invitation> get sentContactInvites =>
      td.invitations
          .where(
            (i) =>
                i.kind == InviteKind.contact &&
                i.direction == InviteDirection.outgoing &&
                i.fromMemberId == td.myId &&
                i.status != InviteStatus.accepted,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void acceptInvite(Invitation inv) {
    inv.status = InviteStatus.accepted;
    if (inv.kind == InviteKind.contact) {
      if (!td.contactIds.contains(inv.fromMemberId)) {
        td.contactIds.add(inv.fromMemberId);
      }
    } else if (inv.kind == InviteKind.group && inv.groupId != null) {
      _joinGroup(inv.groupId!);
    }
    _saveUser();
    notifyListeners();
  }

  void rejectInvite(Invitation inv) {
    inv.status = InviteStatus.rejected;
    notifyListeners();
  }

  /// Cancel/remove an invitation entirely (e.g. cancel my own outgoing request).
  void cancelInvite(Invitation inv) {
    td.invitations.remove(inv);
    notifyListeners();
  }

  // FR-27 KALDIRILDI: "Beni Rehberine Ekleyenler" yüzeyi yoktur. Onaysız
  // doğrudan ekleme tek yönlü ve sessizdir — eklenen kişiye hiçbir iz gitmez
  // (FR-80). Tek gelen kutusu "Onay Bekleyenler"dir (FR-67, incomingInvites).

  // ---- Chats (FR-29..FR-33, text only) ------------------------------------
  /// 1:1 dizi anahtarı **taraf-çiftine** aittir (sıralı `dm:<a>:<b>`), tek
  /// tarafa değil. Eski `dm:<peerId>` anahtarı bakan kimliği yok sayıyordu:
  /// üçüncü bir kimlik başkasının yazışmasını "kendi sohbeti" gibi görüyor,
  /// karşı taraf ise kendi sohbetini bulamıyordu.
  String dmThread(String memberId) {
    final pair = [td.myId, memberId]..sort();
    return 'dm:${pair[0]}:${pair[1]}';
  }

  static String grpThread(String groupId) => 'grp:$groupId';

  List<Message> messagesOf(String threadId) => td.threads[threadId] ?? const [];

  /// Dizide en az bir mesaj var mı — Sohbetler → "HEPSİ" bölümü bunu süzgeç
  /// olarak kullanır (kullanıcı hükmü 2026-07-22). Kategori bölümleri bir
  /// DİZİNdir (üye olunan her grup görünür); HEPSİ ise **gerçek konuşmaların**
  /// listesidir — içi boş grup/kişi orada yer almaz. FR-100'ü ihlal etmez:
  /// içerik/saat yine gösterilmez, yalnız satırın listeye girip girmediği değişir.
  bool hasMessages(String threadId) => messagesOf(threadId).isNotEmpty;

  /// Dizinin son (en yeni) mesajı — yoksa null. Mesajlar gönderim sırasında
  /// eklenir, bu yüzden `.last` en yenidir. HEPSİ önizlemesi/sırası kullanır.
  Message? _lastMessage(String threadId) {
    final msgs = td.threads[threadId];
    return (msgs == null || msgs.isEmpty) ? null : msgs.last;
  }

  /// Mesajı düzenle — YALNIZ kendi mesajın (NFR-17: kısıt veri katmanında).
  void editMessage(String threadId, String messageId, String newText) {
    final t = newText.trim();
    if (t.isEmpty) return;
    for (final m in td.threads[threadId] ?? const <Message>[]) {
      if (m.id == messageId) {
        if (m.senderId != td.myId) return; // başkasının mesajı düzenlenemez
        m.text = t;
        m.edited = true;
        notifyListeners();
        return;
      }
    }
  }

  /// Mesajı bu diziden kaldır (prototip: yerel silme; onaysız — NFR-18).
  void deleteMessage(String threadId, String messageId) {
    td.threads[threadId]?.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  Message? lastMessage(String threadId) {
    final msgs = td.threads[threadId];
    if (msgs == null || msgs.isEmpty) return null;
    return msgs.last;
  }

  void sendDm(String memberId, String text, {String? replyToId}) {
    final t = text.trim();
    if (t.isEmpty) return;
    // FR-18: engellediğim kişiye mesaj gidemez (veri katmanı — NFR-17).
    if (td.blockedIds.contains(memberId)) return;
    final id = dmThread(memberId);
    td.threads.putIfAbsent(id, () => []);
    td.threads[id]!.add(
      Message(
        id: 'm${DateTime.now().microsecondsSinceEpoch}',
        senderId: td.myId, // MUTLAK gönderen (kullanıcı değişince doğru taraf)
        text: t,
        time: DateTime.now(),
        replyToId: replyToId,
      ),
    );
    td.dmVisible.add(memberId); // surfaces the thread in the chat list (FR-32)
    _saveUser(); // dmVisible kişiseldir — kimlik başına saklanır
    // Karşı taraf da bu 1:1'i Sohbetler listesinde HEMEN görsün diye ONUN kayıtlı
    // dmVisible'ına beni ekle (gerçek üründe sunucu/push yapardı). Demo kullanıcı
    // değiştirmede alıcıya geçince mesaj listede belirir.
    _surfaceDmForPeer(memberId);
    notifyListeners();
  }

  /// [peerId]'nin (aktif OLMAYAN) kayıtlı dmVisible'ına beni ekler — böylece o
  /// kimliğe geçilince bu 1:1 Sohbetler listesinde görünür. Kişisel-durum
  /// yalıtımını bozmaz: yalnız "sana biri yazdı → thread listende belirsin"
  /// gerçek davranışını taklit eder.
  void _surfaceDmForPeer(String peerId) {
    final tid = _activeTenantId;
    if (tid == null) return;
    final key = '$tid::$peerId';
    final blob = Map<String, dynamic>.from(_userCache[key] ?? const {});
    final dv =
        ((blob['dv'] as List?)?.cast<String>().toSet() ?? <String>{})
          ..add(td.myId);
    blob['dv'] = dv.toList();
    _userCache[key] = blob;
    _persist(tid, peerId, blob);
  }

  /// FR-90 (yeniden düzenlendi): grup sohbetini GÖREBİLİR miyim?
  /// - manager her zaman görür;
  /// - değilsem, üye olmalıyım (türetilmiş dahil — FR-71) VE grubun
  ///   görünürlüğü ya "tüm üyeler" ya da (yalnız-yetkili ise) rolüm yetkili.
  /// Üyelik tek başına yetmez (kurum sahibi hükmü): öğrenci bölüm üyesidir ama
  /// bölüm "yalnız yetkili" olduğundan sohbetini görmez.
  bool canSeeGroupChat(Group g) {
    if (g.managerId == td.myId) return true;
    if (!isEffectiveMember(g)) return false;
    if (g.visibility == GroupVisibility.allMembers) return true;
    return isAuthority(me); // authorityOnly
  }

  /// FR-90 (yeniden düzenlendi): bu grupta yazabilir miyim?
  /// Manager her zaman yazar; değilse, sohbeti görebiliyor olmam VE grubun
  /// "üyeler yazabilir" anahtarının açık olması gerekir.
  bool canWriteInGroup(Group g) {
    if (g.managerId == td.myId) return true;
    return canSeeGroupChat(g) && g.membersCanWrite;
  }

  /// Bu grubun manager'ı mıyım? İki anahtarı (görünürlük/yazma) yalnız o çevirir.
  bool isGroupManager(Group g) => g.managerId == td.myId;

  /// FR-90: manager, grubun görünürlük/yazma anahtarlarını çevirir.
  void setGroupVisibility(String groupId, GroupVisibility v) {
    final g = td.group(groupId);
    if (g == null || g.managerId != td.myId) return;
    g.visibility = v;
    notifyListeners();
  }

  void setMembersCanWrite(String groupId, bool value) {
    final g = td.group(groupId);
    if (g == null || g.managerId != td.myId) return;
    g.membersCanWrite = value;
    notifyListeners();
  }

  void sendGroupMessage(String groupId, String text, {String? replyToId}) {
    final t = text.trim();
    if (t.isEmpty) return;
    final g = td.group(groupId);
    // FR-90 + NFR-17: yazar-işareti olmayanın gönderimi veri katmanında düşer
    // (UI zaten composer yerine salt-okur şerit gösterir).
    if (g == null || !canWriteInGroup(g)) return;
    final id = grpThread(groupId);
    td.threads.putIfAbsent(id, () => []);
    td.threads[id]!.add(
      Message(
        id: 'm${DateTime.now().microsecondsSinceEpoch}',
        senderId: td.myId, // MUTLAK gönderen (grup üyeleri doğru tarafı görür)
        text: t,
        time: DateTime.now(),
        replyToId: replyToId,
      ),
    );
    notifyListeners();
  }

  bool isDmMuted(String memberId) => td.mutedDms.contains(memberId);
  void toggleDmMute(String memberId) {
    if (!td.mutedDms.remove(memberId)) td.mutedDms.add(memberId);
    _saveUser();
    notifyListeners();
  }

  /// Sessize alma KİŞİSELDİR (FR-49): bakan kimliğin görünümüdür, grubun
  /// kendisinin değil — bu yüzden Group.muted değil, kimlik-başına saklanan
  /// mutedGroupIds kümesidir.
  bool isGroupMuted(String groupId) => td.mutedGroupIds.contains(groupId);
  void toggleGroupMute(String groupId) {
    if (!td.mutedGroupIds.remove(groupId)) td.mutedGroupIds.add(groupId);
    _saveUser();
    notifyListeners();
  }

  /// Unified chat list: group chats the user is in + surfaced 1:1 threads.
  ///
  /// FR-100: satırlar **son mesajı/saatini taşımaz** (liste ekranı içerik
  /// sızdırmaz — E2E ilkesinin liste düzeyi karşılığı) — alt yazı görünüm
  /// katmanında kimlik bilgisinden (grup açıklaması / ünvan · bölüm) üretilir.
  /// Sıralama ada göre alfabetiktir (Gruplar/Kişiler ile tutarlı; "son
  /// aktivite" sırası saat gösterilmeyince açıklanamaz olurdu).
  List<ChatSummary> get chatSummaries {
    final list = <ChatSummary>[];

    for (final g in td.groups) {
      if (g.archived) continue; // arşivlenen grubun sohbeti de listelenmez
      // FR-90: üyelik değil, GÖREBİLME (öğrenci bölüm üyesi ama göremez).
      if (!canSeeGroupChat(g)) continue;
      final last = _lastMessage(grpThread(g.id));
      list.add(
        ChatSummary(
          threadId: grpThread(g.id),
          title: g.name,
          isGroup: true,
          muted: isGroupMuted(g.id),
          group: g,
          lastMessageText: last?.text,
          lastMessageTime: last?.time,
        ),
      );
    }

    for (final peerId in td.dmVisible) {
      final m = td.member(peerId);
      if (m == null) continue;
      final last = _lastMessage(dmThread(peerId));
      list.add(
        ChatSummary(
          threadId: dmThread(peerId),
          title: m.fullName,
          isGroup: false,
          muted: isDmMuted(peerId),
          member: m,
          lastMessageText: last?.text,
          lastMessageTime: last?.time,
        ),
      );
    }

    list.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return list;
  }

  // ---- Groups (FR-34..FR-45) ----------------------------------------------
  // (Tek üyelik kavramı: isEffectiveMember — FR-71 türetilmiş üyelik dahil.
  // Eski isGroupMember yalnız yaprak memberIds'e bakıyordu ve Fakülte gibi
  // türetilmiş-üye olunan düğümlerde Grup Bilgisi'ni yanıltıyordu.)

  // Arşivlenmiş gruplar hiçbir listede görünmez (yalnız Menü → Arşiv'de).
  // "Üye Olduklarım" = sohbetine ERİŞEBİLDİĞİM gruplar (FR-90): göremediğim
  // grubu (ör. öğrenci → bölüm) burada göstermek tıklanınca çıkmaz sokak
  // olurdu. Üyelik yapısı ayrıdır; o Kurum Yapısı'nda (Kurumsal sekmesi)
  // gezilir. Türetilmiş üyelik (FR-71) canSeeGroupChat içinde hesaplanır.
  List<Group> get myGroups =>
      td.groups.where((g) => !g.archived && canSeeGroupChat(g)).toList();

  /// Groups the user has a pending incoming invite for (FR-42).
  /// "Katılabileceklerim" (FR-82) — **yalnız ÖZEL gruplar**, iki kümenin
  /// birleşimi: (a) davet edildiklerim, (b) "açık" işaretlenmiş olanlar.
  ///
  /// Kurumsal gruplar buraya **hiçbir koşulda** girmez (FR-35): kurumsal gruba
  /// ne davet edilir ne de bireysel katılınır. Kapalı özel gruplar ise davet
  /// edilmedikçe görünmez.
  List<Group> get joinableGroups {
    final invitedIds =
        td.invitations
            .where(
              (i) =>
                  i.kind == InviteKind.group &&
                  i.toMemberId == td.myId &&
                  i.status == InviteStatus.pending &&
                  i.groupId != null,
            )
            .map((i) => i.groupId!)
            .toSet();
    return td.groups
        .where(
          (g) =>
              !g.isOrganized &&
              !g.archived &&
              !g.memberIds.contains(td.myId) &&
              (invitedIds.contains(g.id) || g.isOpen),
        )
        .toList();
  }

  /// Bu gruba nasıl dahil olabilirim: davet mi geldi, yoksa açık mı? (FR-82 —
  /// liste ikisini ayırt edilebilir göstermeli.) Davet, açıklığı ezer: davet
  /// geldiyse "Davet" denir.
  bool isInvitedToGroup(String groupId) {
    return td.invitations.any(
      (i) =>
          i.kind == InviteKind.group &&
          i.toMemberId == td.myId &&
          i.status == InviteStatus.pending &&
          i.groupId == groupId,
    );
  }

  /// Özel grubun adını değiştirir — yalnız **grubu kuran üye** (kurum sahibi
  /// hükmü). Kurumsal grupta ve başkasının grubunda hiçbir şey yapmaz (NFR-17).
  void renameGroup(String groupId, String name) {
    final g = td.group(groupId);
    if (g == null || g.isOrganized || g.managerId != td.myId) return;
    final t = name.trim();
    if (t.isEmpty) return;
    g.name = t;
    notifyListeners();
  }

  /// Özel grubun açık/kapalı bayrağını çevirir — yalnız **grubu kuran üye**
  /// (FR-81). Kurumsal grupta ve başkasının grubunda hiçbir şey yapmaz.
  void toggleGroupOpen(String groupId) {
    final g = td.group(groupId);
    if (g == null || g.isOrganized || g.managerId != td.myId) return;
    g.isOpen = !g.isOpen;
    notifyListeners();
  }

  /// Aktif kurumun kurumsal grupları (arşivlenmemiş) — Admin Ayarları'ndaki
  /// açıklama editörü için. Özel gruplar hariçtir: onların açıklamasını grubu
  /// kuran üye Grup Bilgisi'nden yönetir.
  List<Group> get organizedGroupsForAdmin =>
      td.groups.where((g) => g.isOrganized && !g.archived).toList();

  /// Admin (Web-Admin'in karşılığı) bir kurumsal grubun açıklamasını düzenler.
  /// Açıklama kurumsal gruplarda **seed = admin girdisi** olduğundan bu, o
  /// girdiyi prototip içinde canlı düzenlemeye izin verir. Boş bırakılabilir —
  /// boş açıklama Grup Bilgisi'nde gizlenir. Özel grupta hiçbir şey yapmaz.
  void setOrganizedGroupDescription(String groupId, String description) {
    final g = td.group(groupId);
    if (g == null || !g.isOrganized) return;
    g.description = description;
    notifyListeners();
  }

  /// Grubun üye listesi — hiyerarşi düğümlerinde (Fakülte/Bölüm üstü) alt
  /// ağacın birleşimi (FR-71). Grup üyelik bilgisi ortak bağlamdır ve
  /// matrisle SÜZÜLMEZ (FR-21 istisnası — Grup Bilgisi/FR-89 yüzeyleri).
  List<Member> membersOf(Group g) =>
      aggregateMemberIdsOf(
        g,
      ).map((id) => td.member(id)).whereType<Member>().toList();

  /// Ham (süzülmemiş) alt-ağaç üye kümesi: [g] + tüm torunlarının üyeleri.
  /// Üyelik yalnız yaprakta yaşar (FR-71); çocuksuz grupta bu küme grubun
  /// kendi `memberIds`'ine eşittir.
  Set<String> aggregateMemberIdsOf(Group g) {
    final ids = <String>{};
    final seen = <String>{};
    void walk(Group node) {
      if (!seen.add(node.id)) return; // cycle guard
      ids.addAll(node.memberIds);
      for (final c in childGroupsOf(node.id)) {
        walk(c);
      }
    }

    walk(g);
    return ids;
  }

  /// FR-71 türetilmiş üyelik: yaprağa üyeysem tüm atalarına da üyeyim.
  /// (Atanın alt-ağaç birleşimi beni içeriyorsa üyeyim — tek koşulda hem
  /// doğrudan hem türetilmiş üyeliği kapsar.)
  bool isEffectiveMember(Group g) =>
      aggregateMemberIdsOf(g).contains(td.myId);

  /// Satırlarda gösterilen üye sayısı — türetilmiş üyelikle tutarlı, ham
  /// (matris-süzülmemiş) toplam.
  int groupMemberCount(Group g) => aggregateMemberIdsOf(g).length;

  /// Every member of [g] **including all descendant groups**, matris ile
  /// süzülmüş (FR-21, rev.4 — kurum sahibi hükmü: HERKES'te görünmeyen kişi
  /// Kurum Yapısı'nda da görünmez). Yapı düğümleri (Fakülte/Bölüm) bundan
  /// etkilenmez — yalnız kişi listesi/sayısı bakana göre değişir.
  ///
  /// Membership lives only at the **leaf** level (intermediate/parent groups
  /// never get direct members), so a parent's people = the union of its
  /// sub-groups' (visible) people. Sorted by name, de-duplicated.
  List<Member> aggregateMembersOf(Group g) {
    final list =
        aggregateMemberIdsOf(g)
            .map((id) => td.member(id))
            .whereType<Member>()
            .where((m) => canSeeDirectly(me.roleId, m.roleId))
            .toList();
    list.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return list;
  }

  // ---- Group hierarchy (Adım 2) -------------------------------------------
  List<Group> childGroupsOf(String? parentId) =>
      td.groups.where((g) => g.parentGroupId == parentId).toList();

  /// Top-level groups that actually head a hierarchy: either they have
  /// children, or they're explicitly marked as a (leaf) hierarchy root
  /// (`isHierarchyRoot` — e.g. a standalone villa next to apartment blocks).
  /// Plain flat organized groups (a course, a one-off announcement group)
  /// have neither and are correctly excluded.
  List<Group> get treeRootGroups => childGroupsOf(null)
      .where((g) => g.isHierarchyRoot || childGroupsOf(g.id).isNotEmpty)
      .toList();

  bool get hasGroupHierarchy => treeRootGroups.isNotEmpty;

  /// Breadcrumb path from the root down to [g].
  List<Group> groupPath(Group g) {
    final path = <Group>[];
    Group? cur = g;
    final seen = <String>{};
    while (cur != null && seen.add(cur.id)) {
      path.insert(0, cur);
      final pid = cur.parentGroupId;
      cur = pid == null ? null : td.group(pid);
    }
    return path;
  }

  int groupDepth(Group g) => groupPath(g).length - 1;

  /// Deepest level currently in use (1-based). Depth can't be reduced below
  /// this — "kullanım-öncesi" kilit.
  int get usedGroupDepth {
    var maxD = 0;
    for (final g in td.groups) {
      final d = groupDepth(g);
      if (d > maxD) maxD = d;
    }
    return maxD + 1;
  }

  /// Admin-defined label for a tree depth (0-based), with a safe fallback.
  String levelLabel(int depth) {
    final labels = adminSettings.levelLabels;
    return (depth >= 0 && depth < labels.length)
        ? labels[depth]
        : 'Seviye ${depth + 1}';
  }

  List<Group> commonGroups(String memberId) =>
      td.groups
          .where(
            (g) =>
                g.memberIds.contains(td.myId) &&
                g.memberIds.contains(memberId),
          )
          .toList();

  int pendingGroupInvites(String groupId) =>
      td.invitations
          .where(
            (i) =>
                i.kind == InviteKind.group &&
                i.fromMemberId == td.myId &&
                i.groupId == groupId &&
                i.status == InviteStatus.pending,
          )
          .length;

  /// Member ids with a pending outgoing group invite from me for [groupId].
  Set<String> pendingGroupInviteeIds(String groupId) =>
      td.invitations
          .where(
            (i) =>
                i.kind == InviteKind.group &&
                i.groupId == groupId &&
                i.fromMemberId == td.myId &&
                i.status == InviteStatus.pending &&
                i.toMemberId != null,
          )
          .map((i) => i.toMemberId!)
          .toSet();

  /// Cancel a pending outgoing group invite (FR-38 management).
  void cancelGroupInvite(String groupId, String memberId) {
    td.invitations.removeWhere(
      (i) =>
          i.kind == InviteKind.group &&
          i.groupId == groupId &&
          i.toMemberId == memberId &&
          i.fromMemberId == td.myId &&
          i.status == InviteStatus.pending,
    );
    notifyListeners();
  }

  /// Create a private group; the creator becomes first member + Group Admin
  /// (FR-37, FR-41). [autoIncludeIds] join immediately (FR-45, common-group
  /// flow); [invitedIds] receive outgoing invitations (FR-38).
  Group createPrivateGroup({
    required String name,
    required String description,
    String inviteMessage = '',
    IconData? logoIcon,
    List<String> invitedIds = const [],
    List<String> autoIncludeIds = const [],
    // FR-81: katılım bayrağı kuruluşta seçilir, sonra Grup Bilgisi'nden
    // değiştirilebilir. Varsayılan kapalı — açıklık bilinçli bir karardır.
    bool isOpen = false,
    // FR-90: kurucu (=manager) yaratırken seçer; varsayılan yalnız manager
    // yazar (kullanıcı hükmü). Sonradan Grup Bilgisi'nden değiştirilebilir.
    bool membersCanWrite = false,
  }) {
    final id = 'grp_${DateTime.now().microsecondsSinceEpoch}';
    final memberIds = <String>{td.myId, ...autoIncludeIds}.toList();
    final g = Group(
      id: id,
      name: name.trim(),
      description: description.trim(),
      type: GroupType.private,
      managerId: td.myId,
      memberIds: memberIds,
      inviteMessage: inviteMessage.trim(),
      logoIcon: logoIcon,
      isOpen: isOpen,
      membersCanWrite: membersCanWrite,
      // Özel gruplar düzdür (hiyerarşi yalnız kurumsal gruplarda, admin tanımlı).
    );
    td.groups.add(g);
    for (final mid in memberIds) {
      final m = td.member(mid);
      if (m != null && !m.groupIds.contains(id)) {
        m.groupIds = [...m.groupIds, id];
      }
    }
    for (final invitee in invitedIds) {
      td.invitations.add(
        Invitation(
          id: 'out_${DateTime.now().microsecondsSinceEpoch}_$invitee',
          kind: InviteKind.group,
          direction: InviteDirection.outgoing,
          fromMemberId: td.myId,
          toMemberId: invitee,
          groupId: id,
          message: inviteMessage.trim(),
        ),
      );
    }
    notifyListeners();
    return g;
  }

  /// Group Admin invites existing contacts to a private group (FR-38). Records
  /// outgoing invitations; invitees join upon acceptance.
  void inviteMembersToGroup(String groupId, List<String> memberIds) {
    final g = td.group(groupId);
    if (g == null || g.isOrganized) return;
    for (final id in memberIds) {
      if (g.memberIds.contains(id)) continue;
      final dup = td.invitations.any(
        (i) =>
            i.kind == InviteKind.group &&
            i.fromMemberId == td.myId &&
            i.groupId == groupId &&
            i.toMemberId == id &&
            i.status == InviteStatus.pending,
      );
      if (dup) continue;
      td.invitations.add(
        Invitation(
          id: 'out_${DateTime.now().microsecondsSinceEpoch}_$id',
          kind: InviteKind.group,
          direction: InviteDirection.outgoing,
          fromMemberId: td.myId,
          toMemberId: id,
          groupId: groupId,
          message: g.inviteMessage,
        ),
      );
    }
    notifyListeners();
  }

  void _joinGroup(String groupId) {
    final g = td.group(groupId);
    if (g == null) return;
    // FR-35: kurumsal gruba bireysel katılma YOKTUR — üyeliği baştan sona
    // yönetici belirler. (UI zaten kurumsalı listelemiyor; bu, kuralın
    // veri katmanındaki koruması.)
    if (g.isOrganized) return;
    if (!g.memberIds.contains(td.myId)) g.memberIds.add(td.myId);
    final m = me;
    if (!m.groupIds.contains(groupId)) m.groupIds = [...m.groupIds, groupId];
  }

  /// Accept a joinable group and mark the backing invite accepted (FR-42).
  void joinGroup(String groupId) {
    _joinGroup(groupId);
    for (final i in td.invitations) {
      if (i.kind == InviteKind.group &&
          i.toMemberId == td.myId &&
          i.groupId == groupId &&
          i.status == InviteStatus.pending) {
        i.status = InviteStatus.accepted;
      }
    }
    notifyListeners();
  }

  /// Leave a private group (FR-39). Organized groups cannot be left (FR-35).
  void leaveGroup(String groupId) {
    final g = td.group(groupId);
    if (g == null || g.isOrganized) return;
    g.memberIds.remove(td.myId);
    me.groupIds = me.groupIds.where((x) => x != groupId).toList();
    notifyListeners();
  }

  /// Delete a private group — Group Admin only (FR-40).
  /// Grubu arşivle — **yok etmez** (FR-40). Grup ve mesaj dizisi durur; yalnız
  /// herkesin listelerinden kalkar. Kurucusu Arşiv'den geri alabilir.
  ///
  /// Kalıcı silme bilerek **yoktur**: geri alınamaz bir eylem olmadığı için
  /// "Emin misin?" onayı da gerekmez.
  void archiveGroup(String groupId) {
    final g = td.group(groupId);
    if (g == null || g.isOrganized || g.managerId != td.myId) return;
    g.archived = true;
    notifyListeners();
  }

  /// Arşivden geri al — grup mesajlarıyla birlikte eski haline döner.
  void restoreGroup(String groupId) {
    final g = td.group(groupId);
    if (g == null || g.managerId != td.myId) return;
    g.archived = false;
    notifyListeners();
  }

  /// Arşivimdeki gruplar (yalnız kendi kurduklarım — geri alabilen tek kişi).
  List<Group> get archivedGroups =>
      td.groups
          .where((g) => g.archived && g.managerId == td.myId)
          .toList();

  /// Remove a member — Group Admin of a private group only (FR-40).
  void removeGroupMember(String groupId, String memberId) {
    final g = td.group(groupId);
    if (g == null || g.isOrganized || g.managerId != td.myId) return;
    if (memberId == td.myId) return;
    g.memberIds.remove(memberId);
    notifyListeners();
  }

  // ---- Profile & settings (FR-50..FR-54) ----------------------------------
  //
  // updateProfile() KALDIRILDI (FR-50): kimlik alanları (ad-soyad, üye no,
  // bölüm, rol) yöneticiye aittir ve üyeye salt-okunurdur. Üyenin belirlediği
  // TEK alan profil fotoğrafıdır; takma ad ve motto da düşürülmüştür. Üyenin
  // kendi kimliğini yeniden yazabildiği bir API bilerek yoktur.

  void setVisibility(MemberVisibility v) {
    me.visibility = v;
    notifyListeners();
  }

  void setAddPolicy(AddPolicy p) {
    me.addPolicy = p;
    notifyListeners();
  }

  /// Muted conversations for the settings list (FR-49).
  List<ChatSummary> get mutedConversations =>
      chatSummaries.where((c) => c.muted).toList();
}
