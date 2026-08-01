import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/models.dart';
import 'tenant_data.dart';

/// A prototype login identity: which tenants a phone belongs to (FR-7) and
/// which [Member] the user is inside each tenant. Lets the prototype be tested
/// from different people's perspective (e.g. an academic vs a student).
class MockIdentity {
  const MockIdentity({
    required this.phone,
    required this.name,
    required this.tenantIds,
    required this.myIdByTenant,
  });

  /// Full national number, e.g. '5555555501'.
  final String phone;
  final String name;
  final List<String> tenantIds;
  final Map<String, String> myIdByTenant;
}

/// In-memory seed data for the prototype. Two tenants demonstrate multi-tenant
/// isolation (FR-7, FR-8, NFR-6): switching organizations swaps the entire
/// data island. No phone numbers appear anywhere (NFR-5).
class MockData {
  MockData._();

  static const uniId = 'uni';
  static const liseId = 'lise';
  static const siteId = 'site';
  static const dernekId = 'dernek';
  static const hastaneId = 'hastane';

  // ---- Roles (tenant-configured) -----------------------------------------
  static const _academic = Role(
    id: 'academic',
    labelTr: 'Akademisyen',
    labelEn: 'Academic',
    isAuthority: true,
  );
  static const _student = Role(
    id: 'student',
    labelTr: 'Öğrenci',
    labelEn: 'Student',
    isAuthority: false,
  );
  static const _staff = Role(
    id: 'staff',
    // "İdari Personel" terimi iptal (kullanıcı kararı 2026-07-19) — "Personel".
    labelTr: 'Personel',
    labelEn: 'Staff',
    isAuthority: true,
  );
  static const _owner = Role(
    id: 'owner',
    labelTr: 'Ev Sahibi',
    labelEn: 'Home Owner',
    isAuthority: false,
  );
  static const _resident = Role(
    id: 'resident',
    labelTr: 'Sakin',
    labelEn: 'Resident',
    isAuthority: false,
  );
  static const _teacher = Role(
    id: 'teacher',
    labelTr: 'Öğretmen',
    labelEn: 'Teacher',
    isAuthority: true,
  );
  static const _parent = Role(
    id: 'parent',
    labelTr: 'Veli',
    labelEn: 'Parent',
    isAuthority: false,
  );
  static const _manager = Role(
    id: 'manager',
    labelTr: 'Yönetici',
    labelEn: 'Manager',
    isAuthority: true,
  );
  static const _assocMember = Role(
    id: 'assoc_member',
    labelTr: 'Üye',
    labelEn: 'Member',
    isAuthority: false,
  );
  static const _doctor = Role(
    id: 'doctor',
    labelTr: 'Doktor',
    labelEn: 'Doctor',
    isAuthority: true,
  );
  static const _nurse = Role(
    id: 'nurse',
    labelTr: 'Hemşire',
    labelEn: 'Nurse',
    isAuthority: false,
  );

  // Her kuruma farklı marka (logo ikonu + renk) — görünüm vurgu renginin de
  // varsayılan kaynağı (kullanıcı tercihi 2026-07-19).
  static final uniTenant = Tenant(
    id: uniId,
    name: 'Atlas Üniversitesi',
    roles: const [_academic, _student],
    defaultVisibility: MemberVisibility.visible,
    numberSearchEnabled: true,
    numberSearchLabelTr: 'Numaraya göre',
    numberSearchLabelEn: 'By number',
    brandColor: const Color(0xFF1F4E8C), // logo lacivertine yakın
    logoIcon: Icons.school_outlined,
    logoAsset: 'assets/logos/atlas_uni.png',
  );

  static final siteTenant = Tenant(
    id: siteId,
    name: 'Yeşil Vadi Sitesi',
    roles: const [_staff, _owner, _resident],
    defaultVisibility: MemberVisibility.visible,
    numberSearchEnabled: false,
    numberSearchLabelTr: 'Numaraya göre',
    numberSearchLabelEn: 'By number',
    brandColor: const Color(0xFF2E7D32),
    logoIcon: Icons.apartment_outlined,
  );

  static final liseTenant = Tenant(
    id: liseId,
    name: 'Atlas Anadolu Lisesi',
    roles: const [_teacher, _student, _parent],
    defaultVisibility: MemberVisibility.visible,
    numberSearchEnabled: true,
    numberSearchLabelTr: 'Numaraya göre',
    numberSearchLabelEn: 'By number',
    brandColor: const Color(0xFFB07B3A),
    logoIcon: Icons.menu_book_outlined,
  );

  static final dernekTenant = Tenant(
    id: dernekId,
    name: 'Anadolu Kültür Derneği',
    roles: const [_manager, _staff, _assocMember],
    defaultVisibility: MemberVisibility.visible,
    numberSearchEnabled: false,
    numberSearchLabelTr: 'Numaraya göre',
    numberSearchLabelEn: 'By number',
    brandColor: const Color(0xFFC2185B),
    logoIcon: Icons.theater_comedy_outlined,
  );

  static final hastaneTenant = Tenant(
    id: hastaneId,
    name: 'Atlas Şehir Hastanesi',
    roles: const [_doctor, _nurse, _staff],
    defaultVisibility: MemberVisibility.visible,
    numberSearchEnabled: true,
    numberSearchLabelTr: 'Numaraya göre',
    numberSearchLabelEn: 'By number',
    brandColor: const Color(0xFF00838F),
    logoIcon: Icons.local_hospital_outlined,
  );

  static List<Tenant> tenants() =>
      [uniTenant, liseTenant, siteTenant, dernekTenant, hastaneTenant];

  // ---- Login identities (prototype multi-user) ----------------------------
  // The login phone's last two digits pick WHO you are, so the prototype can be
  // exercised from different perspectives. 01=Vedat (academic, all 5 tenants),
  // 02=Suden, 03=Arda (students, university only). Real app: identity comes from
  // the verified phone on the backend.
  static const _idVedat = MockIdentity(
    phone: '5555555501',
    name: 'Vedat Coşkun',
    tenantIds: [uniId, liseId, siteId, dernekId, hastaneId],
    myIdByTenant: {
      uniId: 'u_me',
      liseId: 'l_me',
      siteId: 's_me',
      dernekId: 'd_me',
      hastaneId: 'h_me',
    },
  );
  static const _idSuden = MockIdentity(
    phone: '5555555502',
    name: 'Suden Test',
    tenantIds: [uniId],
    myIdByTenant: {uniId: 'u_zeynep'},
  );
  static const _idArda = MockIdentity(
    phone: '5555555503',
    name: 'Arda Test',
    tenantIds: [uniId],
    myIdByTenant: {uniId: 'u_can'},
  );
  static const _idMerve = MockIdentity(
    phone: '5555555504',
    name: 'Merve Test',
    tenantIds: [uniId],
    myIdByTenant: {uniId: 'u_merve'},
  );

  static const identities = <MockIdentity>[
    _idVedat,
    _idSuden,
    _idArda,
    _idMerve,
  ];

  /// Resolve the login identity from a phone; defaults to the first identity
  /// (Vedat) when the number doesn't match a seeded one.
  static MockIdentity identityForPhone(String phone) {
    for (final id in identities) {
      if (id.phone == phone) return id;
    }
    return _idVedat;
  }

  static Map<String, TenantData> build() => {
    uniId: _buildUniversity(),
    liseId: _buildLise(),
    siteId: _buildSite(),
    dernekId: _buildDernek(),
    hastaneId: _buildHastane(),
  };

  static Member _m(
    String id,
    String name,
    String no,
    String dept,
    Role role, {
    String? course,
    List<String> groups = const [],
    MemberVisibility visibility = MemberVisibility.visible,
  }) {
    // Ünvanı addan ayır: isim ÜNVANSIZ saklanır (sıralama ad-soyada göre),
    // ünvan listede ismin arkasına yazılır ("Mehmet KAYA, Doç. Dr., ...").
    const titles = [
      'Prof. Dr.', 'Doç. Dr.', 'Dr. Öğr. Üyesi', 'Öğr. Gör.',
      'Uzm. Dr.', 'Uzm. Psk.', 'Av.', 'Dr.',
      // Site (Yeşil Vadi) — idari personel ünvanları.
      'Müdür', 'Muhasebeci', 'Güvenlikçi', 'Bahçe İşleri Görevlisi',
      'Temizlikçi',
    ];
    var fullName = name;
    var title = '';
    for (final t in titles) {
      if (name.startsWith('$t ')) {
        title = t;
        fullName = name.substring(t.length + 1);
        break;
      }
    }
    return Member(
      id: id,
      fullName: fullName,
      title: title,
      memberNo: no,
      department: dept,
      roleId: role.id,
      course: course,
      groupIds: groups,
      visibility: visibility,
      isAuthorityRole: role.isAuthority,
    );
  }

  static Message _msg(String id, String sender, String text, DateTime time) =>
      Message(id: id, senderId: sender, text: text, time: time);

  // ---- University tenant --------------------------------------------------
  static TenantData _buildUniversity() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);

    final me = _m(
      'u_me',
      'Vedat Coşkun',
      'A-1010',
      'Bilgisayar Mühendisliği',
      _academic,
      course: 'Yazılım Test Mühendisliği',
      groups: ['g_dept_cs', 'g_test', 'g_bitirme'],
    );
    final ayse = _m(
      'u_ayse',
      'Prof. Dr. Ayşe Demir',
      'A-1021',
      'Bilgisayar Mühendisliği',
      _academic,
      course: 'Yazılım Test Mühendisliği',
      groups: ['g_dept_cs', 'g_test'],
    );
    final mehmet = _m(
      'u_mehmet',
      'Doç. Dr. Mehmet Kaya',
      'A-1044',
      'Elektrik-Elektronik Müh.',
      _academic,
      groups: ['g_chess'],
    );
    final elif = _m(
      'u_elif',
      'Dr. Öğr. Üyesi Elif Yılmaz',
      'A-1075',
      'Bilgisayar Mühendisliği',
      _academic,
      course: 'Veri Yapıları',
      groups: ['g_dept_cs'],
    );
    // Login öğrencileri (Suden, Arda) başlangıçta KENDİNİ GİZLEMİŞ (kullanıcı
    // hükmü 2026-08-01) — böylece görünürlük modeli demo'da hazır görünür: bir
    // öğrenci diğer (görünür) öğrencileri görür ama bu ikisini görmez; yetkili
    // (akademisyen) matris gereği yine hepsini görür. Diğer öğrenciler görünür.
    final zeynep = _m(
      'u_zeynep',
      'Suden Test',
      '2021510012',
      'Bilgisayar Mühendisliği',
      _student,
      course: 'Yazılım Test Mühendisliği',
      groups: ['g_dept_cs', 'g_test', 'g_bitirme'],
      visibility: MemberVisibility.hidden,
    );
    final can = _m(
      'u_can',
      'Arda Test',
      '2021510033',
      'Bilgisayar Mühendisliği',
      _student,
      groups: ['g_dept_cs', 'g_test', 'g_bitirme'],
      visibility: MemberVisibility.hidden,
    );
    // GÖRÜNÜR (varsayılan) demo öğrencisi — login kimliği (04) olarak da Demo
    // sekmesinde; davet-kabul senaryolarında hedef/kabul tarafı için.
    final merve = _m(
      'u_merve',
      'Merve Test',
      '2020430077',
      'Endüstri Mühendisliği',
      _student,
    );
    final burak = _m(
      'u_burak',
      'Burak Arslan',
      '2019360088',
      'Elektrik-Elektronik Müh.',
      _student,
      groups: ['g_chess'],
    );
    final selin = _m(
      'u_selin',
      'Elif Türkmen',
      '2022510099',
      'Bilgisayar Mühendisliği',
      _student,
      course: 'Veri Yapıları',
      groups: ['g_dept_cs'],
    );

    // --- Tasarım Fakültesi: MIS Bölümü + Tasarım Bölümü (kullanıcı hükmü) ---
    final kaan = _m(
      'u_kaan',
      'Doç. Dr. Kaan Sezgin',
      'A-2001',
      'MIS Bölümü',
      _academic,
      groups: ['g_dept_mis'],
    );
    final ece = _m(
      'u_ece',
      'Dr. Öğr. Üyesi Ece Yalman',
      'A-2010',
      'Tasarım Bölümü',
      _academic,
      groups: ['g_dept_design'],
    );
    final efe = _m(
      'u_efe',
      'Efe Karadağ',
      '2023510044',
      'MIS Bölümü',
      _student,
      groups: ['g_dept_mis'],
    );
    final asli = _m(
      'u_asli',
      'Aslı Bozkurt',
      '2023510055',
      'Tasarım Bölümü',
      _student,
      groups: ['g_dept_design'],
    );

    final members = <Member>[
      me,
      ayse,
      mehmet,
      elif,
      zeynep,
      can,
      merve,
      burak,
      selin,
      kaan,
      ece,
      efe,
      asli,
    ];

    final groups = <Group>[
      // Kurum yapısı (hiyerarşi): Dekanlık → Bölüm — Adım 2 demo. Vedat,
      // Bilgisayar Müh. bölümünün (yaprak) üyesidir; FR-71 gereği Fakülteye
      // üyeliği türetilmiştir (Üye Olduklarım + Sohbetler'de ikisi de çıkar).
      Group(
        id: 'g_fac',
        name: 'Mühendislik Fakültesi',
        description: 'Fakülte geneli duyurular.',
        type: GroupType.organized,
        // Ara seviye (Dekanlık) → DOĞRUDAN üyesi yok. Üyelik yalnız en alt
        // seviyededir (Bölüm); fakültenin kişileri = bölümlerinin toplamı.
        memberIds: [],
        logoIcon: Icons.account_balance_outlined,
        // FR-90: manager=dekan; akademik sohbet → yalnız yetkili (akademisyen)
        // görür, öğrenci görmez; yalnız manager yazar (varsayılan).
        managerId: 'u_ayse',
        visibility: GroupVisibility.authorityOnly,
      ),
      Group(
        id: 'g_dept_cs',
        name: 'Bilgisayar Mühendisliği',
        description: '', // opsiyonel — admin girmedi (ad zaten yeterli)
        type: GroupType.organized,
        parentGroupId: 'g_fac',
        memberIds: ['u_me', 'u_ayse', 'u_elif', 'u_zeynep', 'u_can', 'u_selin'],
        logoIcon: Icons.memory_outlined,
        // Bölüm başkanı = manager (kurum sahibi hükmü). Öğrenci üye ama
        // "yalnız yetkili" olduğundan bölüm sohbetini görmez.
        managerId: 'u_ayse',
        visibility: GroupVisibility.authorityOnly,
      ),
      Group(
        id: 'g_dept_ee',
        name: 'Elektrik-Elektronik Müh.',
        description: '',
        type: GroupType.organized,
        parentGroupId: 'g_fac',
        memberIds: ['u_mehmet', 'u_burak'],
        logoIcon: Icons.bolt_outlined,
        managerId: 'u_mehmet',
        visibility: GroupVisibility.authorityOnly,
      ),

      // --- İkinci fakülte (kullanıcı hükmü): Kurumsal artık 2 kök —
      // "tek kök varsa atla" (Kurumsal sekmesi) devreye girmez, kök listesi
      // (Mühendislik + Tasarım) görünür; bu doğru/beklenen, University artık
      // gerçekten çok-köklü.
      Group(
        id: 'g_fac_design',
        name: 'Tasarım Fakültesi',
        description: 'Fakülte geneli duyurular.',
        type: GroupType.organized,
        memberIds: [], // FR-71: ara seviye, üyelik yalnız yaprakta (Bölüm)
        logoIcon: Icons.palette_outlined,
        managerId: 'u_kaan',
        visibility: GroupVisibility.authorityOnly,
      ),
      Group(
        id: 'g_dept_mis',
        name: 'MIS Bölümü',
        description: '',
        type: GroupType.organized,
        parentGroupId: 'g_fac_design',
        memberIds: ['u_kaan', 'u_efe'],
        logoIcon: Icons.dns_outlined,
        managerId: 'u_kaan',
        visibility: GroupVisibility.authorityOnly,
      ),
      Group(
        id: 'g_dept_design',
        name: 'Tasarım Bölümü',
        description: '',
        type: GroupType.organized,
        parentGroupId: 'g_fac_design',
        memberIds: ['u_ece', 'u_asli'],
        logoIcon: Icons.brush_outlined,
        managerId: 'u_ece',
        visibility: GroupVisibility.authorityOnly,
      ),

      // "BM Bölümü Duyuruları" kaldırıldı (kurum sahibi hükmü): hiyerarşideki
      // "Bilgisayar Mühendisliği" (g_dept_cs) üyelikli gerçek grup olunca aynı
      // kişileri içeren düz duyuru grubu gereksiz kopya haline geldi; bölüm
      // duyuruları artık g_dept_cs sohbetinde yaşar (FR-68: duyuru = mesaj).
      Group(
        id: 'g_test',
        name: 'Yazılım Test Dersi',
        description: '', // opsiyonel — admin girmedi
        type: GroupType.organized,
        memberIds: ['u_me', 'u_ayse', 'u_zeynep', 'u_can'],
        logoIcon: Icons.science_outlined,
        // Ders: öğrencinin "kendi dersi" — görünürlük tüm üyeler (öğrenci
        // GÖRÜR), ve tartışma olduğu için herkes yazabilir. Manager=ders
        // sahibi (Vedat).
        managerId: 'u_me',
        membersCanWrite: true,
      ),
      Group(
        id: 'g_bitirme',
        name: 'Bitirme Projesi Ekibi',
        description: 'Bitirme projemiz için çalışma grubu.',
        type: GroupType.private,
        managerId: 'u_me',
        // Özel sohbet grubu: kurucu read-write seçti → her üye yazar.
        membersCanWrite: true,
        memberIds: ['u_me', 'u_zeynep', 'u_can'],
        inviteMessage: 'Bitirme ekibimize katıl!',
        logoIcon: Icons.groups_2_outlined,
      ),
      Group(
        id: 'g_photo',
        name: 'Fotoğrafçılık Kulübü',
        description: 'Kampüste fotoğraf gezileri. Herkes katılabilir.',
        type: GroupType.private,
        managerId: 'u_elif',
        membersCanWrite: true,
        // FR-81: kurucusu "açık" işaretledi → davetsiz katılınır.
        isOpen: true,
        memberIds: ['u_elif', 'u_selin'],
        inviteMessage: '',
        logoIcon: Icons.photo_camera_outlined,
      ),
      Group(
        id: 'g_chess',
        name: 'Satranç Kulübü',
        description: 'Kampüs satranç buluşmaları ve turnuvalar.',
        type: GroupType.private,
        managerId: 'u_mehmet',
        membersCanWrite: true,
        memberIds: ['u_mehmet', 'u_burak'],
        inviteMessage: 'Satranç kulübüne davetlisin!',
        logoIcon: Icons.extension_outlined,
      ),
    ];

    final invitations = <Invitation>[
      // Incoming contact invite: a student wants to add me (FR-28).
      Invitation(
        id: 'inv_merve',
        kind: InviteKind.contact,
        direction: InviteDirection.incoming,
        fromMemberId: 'u_merve',
        toMemberId: 'u_me',
        message: 'Merhaba, endüstri-yazılım ortak projesi için konuşabilir miyiz?',
      ),
      // Incoming group invite drives "Katılabileceklerim" (FR-42, FR-38).
      Invitation(
        id: 'inv_chess',
        kind: InviteKind.group,
        direction: InviteDirection.incoming,
        fromMemberId: 'u_mehmet',
        toMemberId: 'u_me',
        groupId: 'g_chess',
        message: 'Satranç kulübüne davetlisin!',
      ),
      // Vedat'ın GÖNDERDİĞİ rehber davetleri — "Davetler → Gönderdiğim"
      // geçmişini doldurur (durum + tarih). NOT: Vedat akademisyendir ve matris
      // gereği herkesi DOĞRUDAN ekler → onay davetleri (dolayısıyla "beklemede"
      // durumu) onun için oluşmaz; bu yüzden yalnız kabul/red geçmişi seed'lenir
      // (bunlar reconcile'a takılmaz). Bekleyen durum temel-rol (öğrenci)
      // kullanıcılarında görülür.
      Invitation(
        id: 'sent_ece',
        kind: InviteKind.contact,
        direction: InviteDirection.outgoing,
        fromMemberId: 'u_me',
        toMemberId: 'u_ece',
        message: 'Tasarım tarafı için tanışalım.',
        status: InviteStatus.accepted,
        createdAt: ago(const Duration(days: 5, hours: 6)),
      ),
      Invitation(
        id: 'sent_asli',
        kind: InviteKind.contact,
        direction: InviteDirection.outgoing,
        fromMemberId: 'u_me',
        toMemberId: 'u_asli',
        message: 'Rehberime eklemek istedim.',
        status: InviteStatus.rejected,
        createdAt: ago(const Duration(days: 12)),
      ),
    ];

    // Zaman damgaları BİLİNÇLİ olarak çeşitli: bugün (SS:dd), dün ("Dün") ve
    // birkaç gün öncesi (gg.aa) — HEPSİ gelen-kutusunun saat biçimi + son-
    // aktivite sıralaması gerçekçi görünsün (kullanıcı: "zengin mock veri").
    final threads = <String, List<Message>>{
      // === Kişisel (1:1) ===
      // Suden — en yeni (bugün, ~8 dk önce).
      'dm:u_me:u_zeynep': [
        _msg('z1', 'u_me', 'Suden, bitirme sunumunu ne zaman yapıyoruz?',
            ago(const Duration(hours: 3))),
        _msg('z2', 'u_zeynep', 'Cuma öğleden sonra uygun.',
            ago(const Duration(hours: 2, minutes: 50))),
        _msg('z3', 'u_me', 'Cuma 15:00 olsun o zaman.',
            ago(const Duration(minutes: 12))),
        _msg('z4', 'u_zeynep', 'Harika, slaytları akşam atarım.',
            ago(const Duration(minutes: 8))),
      ],
      // Ayşe (bugün, ~35 dk önce).
      'dm:u_ayse:u_me': [
        _msg('a1', 'u_ayse', 'Merhaba Vedat, ödev teslimini aldım.',
            ago(const Duration(hours: 2))),
        _msg('a2', 'u_me', 'Teşekkürler hocam, iyi günler.',
            ago(const Duration(hours: 1, minutes: 55))),
        _msg('a3', 'u_ayse', 'Yarınki derste test otomasyonuna bakacağız.',
            ago(const Duration(minutes: 35))),
      ],
      // Selin (dün → "Dün"). (Not: Can'la DM eklenmez — user_scoping testi
      // Can'ın Vedat'la yazışmasının BOŞ olmasına dayanır.)
      'dm:u_me:u_selin': [
        _msg('ds1', 'u_selin', 'Hocam, lab raporu için şablon var mı?',
            ago(const Duration(days: 1, hours: 4))),
        _msg('ds2', 'u_me', 'Evet, ders grubuna yükledim.',
            ago(const Duration(days: 1, hours: 3, minutes: 30))),
        _msg('ds3', 'u_selin', 'Buldum, teşekkürler!',
            ago(const Duration(days: 1, hours: 3))),
      ],
      // Elif (birkaç gün önce → gg.aa).
      'dm:u_elif:u_me': [
        _msg('de1', 'u_elif', 'Ortak makale için müsait misin?',
            ago(const Duration(days: 3, hours: 2))),
        _msg('de2', 'u_me', 'Önümüzdeki hafta oturalım.',
            ago(const Duration(days: 3, hours: 1))),
      ],

      // === Kurumsal / özel grup sohbetleri ===
      // Bitirme ekibi (bugün, ~70 dk önce).
      'grp:g_bitirme': [
        _msg('b1', 'u_zeynep', 'Arayüz kısmını ben hallederim.',
            ago(const Duration(minutes: 90))),
        _msg('b2', 'u_can', 'Ben de backend mock’unu yazıyorum.',
            ago(const Duration(minutes: 80))),
        _msg('b3', 'u_me', 'Süper, yarın senkron olalım.',
            ago(const Duration(minutes: 70))),
      ],
      // Bilgisayar Müh. bölümü (bugün, birkaç saat). Duyurular g_dept_cs'te (FR-68).
      'grp:g_dept_cs': [
        _msg('c1', 'u_ayse', 'Bu hafta bölüm semineri Cuma 14:00’te.',
            ago(const Duration(hours: 5))),
        _msg('c2', 'u_elif', 'Katılım zorunlu mu hocam?',
            ago(const Duration(hours: 4))),
        _msg('c3', 'u_ayse', 'Tavsiye edilir, zorunlu değil.',
            ago(const Duration(hours: 3))),
      ],
      // Yazılım Test Dersi (bugün, ~6 saat).
      'grp:g_test': [
        _msg('t1', 'u_ayse', 'Proje raporlarını Pazar’a kadar yükleyin.',
            ago(const Duration(hours: 8))),
        _msg('t2', 'u_can', 'Grup halinde mi bireysel mi hocam?',
            ago(const Duration(hours: 7))),
        _msg('t3', 'u_me', 'Ben Suden ile grup yapıyorum.',
            ago(const Duration(hours: 6))),
      ],
      // Mühendislik Fakültesi (dün) — akademisyen sohbeti (yalnız yetkili görür).
      'grp:g_fac': [
        _msg('f1', 'u_ayse', 'Fakülte kurulu toplantısı Perşembe 10:00.',
            ago(const Duration(days: 1, hours: 6))),
        _msg('f2', 'u_mehmet', 'Gündeme bütçe kalemini ekleyelim.',
            ago(const Duration(days: 1, hours: 5))),
      ],
    };

    return TenantData(
      tenant: uniTenant,
      myId: 'u_me',
      members: {for (final m in members) m.id: m},
      groups: groups,
      invitations: invitations,
      threads: threads,
      // İlk açılışta HEPSİ dolu görünsün diye Vedat'ın geçmişi olan 1:1'leri
      // yüzeyde (KİMLİK-BAŞINA seed — kayıtlı blob yoksa geri dönülür, bkz.
      // TenantData.initialDmVisibleByMyId). Yalnız u_me seed'lenir → başka
      // kimliğe sızmaz. Kullanıcı gizlerse blob'a yazılır.
      initialDmVisibleByMyId: const {
        'u_me': {'u_ayse', 'u_zeynep', 'u_selin', 'u_elif'},
      },
      // Rehber starts empty (FR-20). First-login profile setup is skipped:
      // identity fields are admin-owned/read-only, so there is nothing for the
      // user to set here (a photo can be added later from Profil).
      contactIds: [],
      profileComplete: true,
    );
  }

  // ---- Housing-site tenant ------------------------------------------------
  // Kurum sahibi hükmü: Vedat = Müdür (idari personel); iki blok (Mavi,
  // Yeşil — üçer daire) + iki bağımsız villa (Deniz, Orman) hiyerarşisi.
  static TenantData _buildSite() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);

    // --- İdari personel ---
    final me = _m(
      's_me',
      'Müdür Vedat Coşkun',
      'P-01',
      'Site Yönetimi',
      _staff,
      groups: ['sg_idari'],
    );
    final muhasebeci = _m(
      's_muhasebe',
      'Muhasebeci Kemal Öztürk',
      'P-02',
      'Site Yönetimi',
      _staff,
      groups: ['sg_idari'],
    );
    final guvenlik1 = _m(
      's_guv1',
      'Güvenlikçi Hasan Güneş',
      'P-03',
      'Güvenlik',
      _staff,
      groups: ['sg_idari'],
    );
    final guvenlik2 = _m(
      's_guv2',
      'Güvenlikçi İsmail Kurt',
      'P-04',
      'Güvenlik',
      _staff,
      groups: ['sg_idari'],
    );
    final bahce1 = _m(
      's_bahce1',
      'Bahçe İşleri Görevlisi Yusuf Aydemir',
      'P-05',
      'Bahçe Bakımı',
      _staff,
      groups: ['sg_idari'],
    );
    final bahce2 = _m(
      's_bahce2',
      'Bahçe İşleri Görevlisi Mustafa Bulut',
      'P-06',
      'Bahçe Bakımı',
      _staff,
      groups: ['sg_idari'],
    );
    final temizlik1 = _m(
      's_temiz1',
      'Temizlikçi Hatice Şimşek',
      'P-07',
      'Temizlik',
      _staff,
      groups: ['sg_idari'],
    );
    final temizlik2 = _m(
      's_temiz2',
      'Temizlikçi Emine Korkmaz',
      'P-08',
      'Temizlik',
      _staff,
      groups: ['sg_idari'],
    );

    // --- Sakinler: Mavi Blok (3 daire) ---
    final mavi1 = _m('s_mavi1', 'Kerem Yalçın', 'K-01', 'Mavi Blok - Daire 1',
        _owner, groups: ['sg_mavi_1']);
    final mavi2 = _m('s_mavi2', 'Derya Aksakal', 'K-02', 'Mavi Blok - Daire 2',
        _resident, groups: ['sg_mavi_2']);
    final mavi3 = _m('s_mavi3', 'Tolga Erdem', 'K-03', 'Mavi Blok - Daire 3',
        _owner, groups: ['sg_mavi_3']);

    // --- Sakinler: Yeşil Blok (3 daire) ---
    final yesil1 = _m('s_yesil1', 'Pınar Çelik', 'K-04',
        'Yeşil Blok - Daire 1', _owner, groups: ['sg_yesil_1']);
    final yesil2 = _m('s_yesil2', 'Volkan Tunç', 'K-05',
        'Yeşil Blok - Daire 2', _resident, groups: ['sg_yesil_2']);
    final yesil3 = _m('s_yesil3', 'Gizem Polat', 'K-06',
        'Yeşil Blok - Daire 3', _owner, groups: ['sg_yesil_3']);

    // --- Bağımsız villalar (bloklara bağlı değil, kendi başına kök) ---
    final deniz = _m('s_deniz', 'Cem Yıldırım', 'K-07', 'Deniz Villa', _owner,
        groups: ['sg_deniz']);
    final orman = _m('s_orman', 'Ebru Kaplan', 'K-08', 'Orman Villa', _owner,
        groups: ['sg_orman']);

    final members = <Member>[
      me, muhasebeci, guvenlik1, guvenlik2, bahce1, bahce2, temizlik1,
      temizlik2, mavi1, mavi2, mavi3, yesil1, yesil2, yesil3, deniz, orman,
    ];

    // Kurum sahibi hükmü: kök üç KATEGORİ'dir (Personel / Ev Sahibi /
    // Sakin — admin ayarlarındaki roller). Personel çocuksuz (üyeler
    // doğrudan onun altında). Ev Sahibi ve Sakin altında Mavi Blok/Yeşil Blok
    // AYRI AYRI tekrarlanır — her biri yalnız o kategoriden sakini olan
    // daireleri toplar (aynı isim, iki farklı düğüm/id — kullanıcı hükmü).
    // "Site Duyuruları" düz grubu KALDIRILDI (kullanıcı kararı 2026-07-19):
    // site-geneli duyurular artık Sakin kategori-kökünün sohbetinden yapılır;
    // manager'ı Personel'den Site Yöneticisi (s_me).
    final groups = <Group>[
      // --- KATEGORİ: Personel (kök, çocuksuz — isHierarchyRoot) ---
      Group(
        id: 'sg_idari',
        name: 'Personel',
        description: 'Site yönetim ve bakım ekibi.',
        type: GroupType.organized,
        memberIds: const [
          's_me', 's_muhasebe', 's_guv1', 's_guv2',
          's_bahce1', 's_bahce2', 's_temiz1', 's_temiz2',
        ],
        logoIcon: Icons.badge_outlined,
        managerId: 's_me',
        // Personel koordinasyon grubu: hepsi idari (yetkili), herkes yazar.
        membersCanWrite: true,
        isHierarchyRoot: true,
      ),

      // --- KATEGORİ: Sakin (kök) → Mavi/Yeşil Blok (kiracı daireleri) ---
      // Kök sırası = liste sırası (kullanıcı hükmü): Personel, Sakin, Ev Sahibi.
      Group(
        id: 'sg_sakin',
        name: 'Sakin',
        description: 'Kiracı/sakin sakinler. Site duyuruları buradan yapılır.',
        type: GroupType.organized,
        memberIds: const [],
        logoIcon: Icons.groups_outlined,
        // Site-geneli duyuru kanalı — manager: Site Yöneticisi (Personel'den).
        managerId: 's_me',
      ),
      Group(
        id: 'sg_mavi_sakin',
        name: 'Mavi Blok',
        description: 'Mavi Blok — sakin dairesi.',
        type: GroupType.organized,
        parentGroupId: 'sg_sakin',
        memberIds: const [],
        logoIcon: Icons.apartment_outlined,
        managerId: 's_me',
      ),
      Group(
        id: 'sg_mavi_2',
        name: 'Daire 2',
        description: 'Mavi Blok Daire 2.',
        type: GroupType.organized,
        parentGroupId: 'sg_mavi_sakin',
        memberIds: const ['s_mavi2'],
        logoIcon: Icons.door_front_door_outlined,
        managerId: 's_mavi2',
      ),
      Group(
        id: 'sg_yesil_sakin',
        name: 'Yeşil Blok',
        description: 'Yeşil Blok — sakin dairesi.',
        type: GroupType.organized,
        parentGroupId: 'sg_sakin',
        memberIds: const [],
        logoIcon: Icons.apartment_outlined,
        managerId: 's_me',
      ),
      Group(
        id: 'sg_yesil_2',
        name: 'Daire 2',
        description: 'Yeşil Blok Daire 2.',
        type: GroupType.organized,
        parentGroupId: 'sg_yesil_sakin',
        memberIds: const ['s_yesil2'],
        logoIcon: Icons.door_front_door_outlined,
        managerId: 's_yesil2',
      ),

      // --- KATEGORİ: Ev Sahibi (kök) → Mavi/Yeşil Blok (sahip daireleri) + villalar ---
      Group(
        id: 'sg_sahip',
        name: 'Ev Sahibi',
        description: 'Mülk sahibi sakinler.',
        type: GroupType.organized,
        memberIds: const [],
        logoIcon: Icons.key_outlined,
        // FR-90: kabuk düğümlerde de site müdürü manager — duyuru kanalı
        // (kullanıcı kararı 2026-07-19); üyeler okur, yalnız manager yazar.
        managerId: 's_me',
      ),
      Group(
        id: 'sg_mavi_sahip',
        name: 'Mavi Blok',
        description: 'Mavi Blok — sahip daireleri.',
        type: GroupType.organized,
        parentGroupId: 'sg_sahip',
        memberIds: const [],
        logoIcon: Icons.apartment_outlined,
        managerId: 's_me',
      ),
      Group(
        id: 'sg_mavi_1',
        name: 'Daire 1',
        description: 'Mavi Blok Daire 1.',
        type: GroupType.organized,
        parentGroupId: 'sg_mavi_sahip',
        memberIds: const ['s_mavi1'],
        logoIcon: Icons.door_front_door_outlined,
        managerId: 's_mavi1', // kendi dairesinde sakin yazar
      ),
      Group(
        id: 'sg_mavi_3',
        name: 'Daire 3',
        description: 'Mavi Blok Daire 3.',
        type: GroupType.organized,
        parentGroupId: 'sg_mavi_sahip',
        memberIds: const ['s_mavi3'],
        logoIcon: Icons.door_front_door_outlined,
        managerId: 's_mavi3',
      ),
      Group(
        id: 'sg_yesil_sahip',
        name: 'Yeşil Blok',
        description: 'Yeşil Blok — sahip daireleri.',
        type: GroupType.organized,
        parentGroupId: 'sg_sahip',
        memberIds: const [],
        logoIcon: Icons.apartment_outlined,
        managerId: 's_me',
      ),
      Group(
        id: 'sg_yesil_1',
        name: 'Daire 1',
        description: 'Yeşil Blok Daire 1.',
        type: GroupType.organized,
        parentGroupId: 'sg_yesil_sahip',
        memberIds: const ['s_yesil1'],
        logoIcon: Icons.door_front_door_outlined,
        managerId: 's_yesil1',
      ),
      Group(
        id: 'sg_yesil_3',
        name: 'Daire 3',
        description: 'Yeşil Blok Daire 3.',
        type: GroupType.organized,
        parentGroupId: 'sg_yesil_sahip',
        memberIds: const ['s_yesil3'],
        logoIcon: Icons.door_front_door_outlined,
        managerId: 's_yesil3',
      ),
      // Villalar: bloklara ayrılmaz, doğrudan Ev Sahibi'nin yaprağı — sahipli.
      Group(
        id: 'sg_deniz',
        name: 'Deniz Villa',
        description: 'Bağımsız villa.',
        type: GroupType.organized,
        parentGroupId: 'sg_sahip',
        memberIds: const ['s_deniz'],
        logoIcon: Icons.villa_outlined,
        managerId: 's_deniz',
      ),
      Group(
        id: 'sg_orman',
        name: 'Orman Villa',
        description: 'Bağımsız villa.',
        type: GroupType.organized,
        parentGroupId: 'sg_sahip',
        memberIds: const ['s_orman'],
        logoIcon: Icons.villa_outlined,
        managerId: 's_orman',
      ),
    ];

    final threads = <String, List<Message>>{
      // Site-geneli duyurular Sakin kökünün sohbetinde; yalnız manager (s_me)
      // yazabildiğinden seed mesajlar da ondan (muhasebeci FR-90 gereği
      // yazamaz — aidat duyurusunu da yönetici geçer).
      'grp:sg_sakin': [
        _msg('sa1', 's_me', 'Su kesintisi yarın 09:00-12:00 arası olacaktır.',
            ago(const Duration(hours: 4))),
        _msg('sa2', 's_me', 'Aidat son ödeme tarihi bu ayın 10\'u.',
            ago(const Duration(hours: 3))),
      ],
    };

    return TenantData(
      tenant: siteTenant,
      myId: 's_me',
      members: {for (final m in members) m.id: m},
      groups: groups,
      invitations: [],
      threads: threads,
      contactIds: [],
      // Second tenant already onboarded, so switching to it skips setup.
      profileComplete: true,
    );
  }

  // ---- High-school tenant (Öğretmen / Öğrenci / Veli) ---------------------
  static TenantData _buildLise() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);

    final me = _m('l_me', 'Vedat Coşkun', 'Ö-204', 'Fen Bilimleri', _teacher,
        groups: ['lg_9a', 'lg_ann', 'lg_veli']);
    final ahmet = _m('l_ahmet', 'Ahmet Yıldız', '1024', '9-A', _student,
        groups: ['lg_9a', 'lg_ann']);
    final ogr2 = _m('l_ogr2', 'Fatih Şahin', 'Ö-118', 'Matematik', _teacher,
        groups: ['lg_ann']);
    final veli = _m('l_veli', 'Zehra Aksoy', 'V-1024',
        'Veli (Ahmet Yıldız)', _parent, groups: ['lg_ann', 'lg_veli']);

    final members = <Member>[me, ahmet, ogr2, veli];

    final groups = <Group>[
      Group(
        id: 'lg_9a',
        name: '9-A Sınıfı',
        description: '9-A şubesi ders ve iletişim grubu.',
        type: GroupType.organized,
        memberIds: ['l_me', 'l_ahmet'],
        logoIcon: Icons.class_outlined,
        managerId: 'l_me', // FR-90
      ),
      Group(
        id: 'lg_ann',
        name: 'Okul Duyuruları',
        description: 'Tüm okul için resmi duyurular.',
        type: GroupType.organized,
        memberIds: ['l_me', 'l_ahmet', 'l_ogr2', 'l_veli'],
        logoIcon: Icons.campaign_outlined,
        managerId: 'l_me', // FR-90: öğretmenler yazar
      ),
      Group(
        id: 'lg_veli',
        name: '9-A Veli Grubu',
        description: '9-A velileri ile iletişim.',
        type: GroupType.organized,
        memberIds: ['l_me', 'l_veli'],
        logoIcon: Icons.groups_outlined,
        managerId: 'l_me', // FR-90
      ),
    ];

    final threads = <String, List<Message>>{
      'grp:lg_ann': [
        _msg('la1', 'l_me',
            'Yarın 1. ders veli toplantısı nedeniyle 1 saat geç başlayacaktır.',
            ago(const Duration(hours: 3))),
      ],
      'grp:lg_9a': [
        _msg('l9a1', 'l_me', 'Bugünkü fizik ödevini akşam paylaşacağım.',
            ago(const Duration(hours: 1))),
      ],
    };

    return TenantData(
      tenant: liseTenant,
      myId: 'l_me',
      members: {for (final m in members) m.id: m},
      groups: groups,
      invitations: const [],
      threads: threads,
      contactIds: const [],
      profileComplete: true,
    );
  }

  // ---- Association tenant (Yönetici / Personel / Üye) ---------------------
  static TenantData _buildDernek() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);

    final me = _m('d_me', 'Vedat Coşkun', 'Y-01', 'Yönetim Kurulu', _manager,
        groups: ['dg_yk', 'dg_uye', 'dg_etkinlik']);
    final selim = _m('d_selim', 'Selim Kaya', 'Ü-231', 'Üye', _assocMember,
        groups: ['dg_uye']);
    final aylin = _m('d_aylin', 'Aylin Doğan', 'Ü-232', 'Üye', _assocMember,
        groups: ['dg_uye', 'dg_etkinlik']);
    final nur = _m('d_nur', 'Nur Aydın', 'P-05', 'Personel', _staff,
        groups: ['dg_yk', 'dg_uye']);

    final members = <Member>[me, selim, aylin, nur];

    final groups = <Group>[
      Group(
        id: 'dg_yk',
        name: 'Yönetim Kurulu',
        description: 'Yönetim kurulu iletişimi.',
        type: GroupType.organized,
        memberIds: ['d_me', 'd_nur'],
        logoIcon: Icons.account_balance_outlined,
        managerId: 'd_me', // FR-90
      ),
      Group(
        id: 'dg_uye',
        name: 'Üye Grubu',
        description: 'Tüm dernek üyeleri.',
        type: GroupType.organized,
        memberIds: ['d_me', 'd_selim', 'd_aylin', 'd_nur'],
        logoIcon: Icons.people_outline,
        managerId: 'd_me', // FR-90: yönetici + idari personel
      ),
      Group(
        id: 'dg_etkinlik',
        name: 'Etkinlik Çalışma Grubu',
        description: 'Yıl sonu etkinliği çalışma grubu.',
        type: GroupType.private,
        managerId: 'd_me',
        memberIds: ['d_me', 'd_aylin'],
        inviteMessage: 'Etkinlik ekibine katıl!',
        logoIcon: Icons.workspaces_outlined,
      ),
    ];

    final threads = <String, List<Message>>{
      'grp:dg_yk': [
        _msg('dy1', 'd_nur',
            'Bütçe raporunu paylaştım, gözden geçirir misiniz?',
            ago(const Duration(hours: 4))),
        _msg('dy2', 'd_me', 'Teşekkürler, akşam bakıp döneceğim.',
            ago(const Duration(hours: 3, minutes: 30))),
      ],
    };

    return TenantData(
      tenant: dernekTenant,
      myId: 'd_me',
      members: {for (final m in members) m.id: m},
      groups: groups,
      invitations: const [],
      threads: threads,
      contactIds: const [],
      profileComplete: true,
    );
  }

  // ---- Hospital tenant (Doktor / Hemşire / Personel) ----------------------
  static TenantData _buildHastane() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);

    final me = _m('h_me', 'Vedat Coşkun', 'D-77', 'Kardiyoloji', _doctor,
        groups: ['hg_kardiyo', 'hg_nobet', 'hg_ann']);
    final murat = _m('h_murat', 'Murat Aslan', 'D-45', 'Acil', _doctor,
        groups: ['hg_nobet', 'hg_ann']);
    final elif = _m('h_elif', 'Elif Kaya', 'H-210', 'Kardiyoloji', _nurse,
        groups: ['hg_kardiyo', 'hg_nobet']);
    final sema = _m('h_sema', 'Sema Yıldız', 'P-12', 'İnsan Kaynakları', _staff,
        groups: ['hg_ann']);

    final members = <Member>[me, murat, elif, sema];

    final groups = <Group>[
      Group(
        id: 'hg_kardiyo',
        name: 'Kardiyoloji Servisi',
        description: 'Kardiyoloji servisi ekip iletişimi.',
        type: GroupType.organized,
        memberIds: ['h_me', 'h_elif'],
        logoIcon: Icons.local_hospital_outlined,
        managerId: 'h_me', // FR-90
      ),
      Group(
        id: 'hg_nobet',
        name: 'Nöbet Grubu',
        description: 'Nöbet çizelgesi ve devir teslim.',
        type: GroupType.organized,
        memberIds: ['h_me', 'h_murat', 'h_elif'],
        logoIcon: Icons.schedule_outlined,
        managerId: 'h_me', // FR-90
      ),
      Group(
        id: 'hg_ann',
        name: 'Hastane Duyuruları',
        description: 'Tüm personel için duyurular.',
        type: GroupType.organized,
        memberIds: ['h_me', 'h_murat', 'h_elif', 'h_sema'],
        logoIcon: Icons.campaign_outlined,
        managerId: 'h_sema', // FR-90: duyuruları İK yazar; doktorlar okur
      ),
    ];

    final threads = <String, List<Message>>{
      'grp:hg_nobet': [
        _msg('hn1', 'h_murat', 'Bu gece acil nöbetini ben devralıyorum.',
            ago(const Duration(hours: 2))),
        _msg('hn2', 'h_elif',
            'Kardiyolojide 3 hasta takipte, notları girdim.',
            ago(const Duration(hours: 1, minutes: 40))),
      ],
    };

    return TenantData(
      tenant: hastaneTenant,
      myId: 'h_me',
      members: {for (final m in members) m.id: m},
      groups: groups,
      invitations: const [],
      threads: threads,
      contactIds: const [],
      profileComplete: true,
    );
  }
}

/// PROTOTİP KISAYOLU — gereksinim dondurulurken kaldırılacak.
///
/// Prototipte kimlik telefonun son rakamıyla seçiliyor (1=Vedat, 2=Suden,
/// 3=Arda). Listelerde kimin hangi rakamla giriş yapıldığını görebilmek için
/// ismin yanına o rakamı yazıyoruz. Gerçek sürümde kimlik backend'den gelir ve
/// böyle bir ipucu olmaz.
extension MemberLoginHint on Member {
  /// Bu üye login olunabilen bir test kimliğiyse telefonun son rakamı; yoksa null.
  String? get loginDigit {
    for (final i in MockData.identities) {
      if (i.myIdByTenant.containsValue(id)) {
        return i.phone.substring(i.phone.length - 1);
      }
    }
    return null;
  }

  /// İsim + (varsa) boşluk + login rakamı — ör. "Arda Yetkin 3".
  String get displayName {
    final d = loginDigit;
    return d == null ? fullName : '$fullName $d';
  }
}
