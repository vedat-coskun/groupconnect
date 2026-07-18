/// Lightweight in-app localization (FR-11, NFR-15).
///
/// The prototype is Turkish-first; toggling the language in Settings switches
/// every chrome label to English. Content (mock names / seeded messages) is
/// left as authored. A real app would swap this for gen-l10n/arb, but the
/// call sites (`context.s.chats`) stay identical.
library;

import 'package:flutter/widgets.dart';

import '../models/enums.dart';
import '../state/app_scope.dart';

/// Base contract — one getter/method per user-visible label.
abstract class AppStrings {
  const AppStrings();

  factory AppStrings.of(AppLanguage lang) =>
      lang == AppLanguage.tr ? const _Tr() : const _En();

  String get appName;
  String get tagline;

  // Generic actions
  String get ok;
  String get cancel;
  String get save;

  /// Seçimi yürürlüğe koyan buton — "Kaydet"ten farkı: yalnız eklemez, geri
  /// alınan seçimlerin davetini de iptal eder (iki yönlü senkron).
  String get apply;
  String get send;
  String get add;
  String get selectAll;
  String get clearSelection;
  String contactsAddedSummary(int added, int invited);
  String get remove;
  String get delete;
  String get edit;
  String get done;
  String get next;
  String get skip;
  String get search;
  String get join;
  String get leave;
  String get accept;
  String get reject;
  String get create;
  String get all;

  // Bottom navigation
  String get tabChats;
  String get tabContacts;
  String get tabGroups;
  String get tabProfile;
  String get tabMenu;

  // Onboarding
  String get onbTitle1;
  String get onbBody1;
  String get onbTitle2;
  String get onbBody2;
  String get onbTitle3;
  String get onbBody3;
  String get start;

  // Auth
  String get phoneTitle;
  String get phoneSubtitle;
  String get phoneHelp;
  String get continueLabel;
  String get otpTitle;
  String otpSubtitle(String phone);
  String get resend;
  String get otpError;
  String get verifying;
  String get tenantSelectTitle;
  String get tenantSelectSubtitle;
  String get rememberTenant;
  String get rememberTenantHint;

  // Profile setup
  String get profileSetupTitle;
  String get profileSetupHint;
  String get fullName;
  String get memberNo;
  String get department;
  String get role;
  String get course;

  // Chats
  String get chatsTitle;
  String get chatsEmpty;
  String get chatsEmptyHint;
  String get chatsFilterPersonal;
  String get chatsFilterEmpty;
  String get newChatTitle;
  String get messageHint;
  String get reply;
  String get copy;
  String get editedTag;
  String get messageDeleted;
  String get notInContactsYet;
  String get introHint;
  String get today;

  // Contacts / directory
  String get contactsTitle;
  String get everyoneTab;
  String get myContactsTab;
  String get addedMeTab;
  String get sentInvites;
  String get approvedSection;
  String get contactsEmpty;
  String get contactsEmptyHint;
  String get addContact;
  String get directoryTitle;
  String get sortByName;
  String get sortByNumber;
  String get filterRole;
  String get filterDepartment;
  String get filterCourse;
  String get filterGroup;
  String get noResults;
  String get addToContacts;
  String get sendMessage;
  String get commonGroups;
  String get noCommonGroups;
  String get removeFromContacts;
  String addedDirectly(String name);
  String removedFromContacts(String name);
  String get inviteSent;
  String get inviteMessageHint;
  String get favorite;
  String get addFavorite;
  String get removeFavorite;
  String get notes;
  String get notesHint;
  String get memberNoLabel;
  String get roleLabel;
  String get departmentLabel;
  String get alreadyInContacts;
  String get block;
  String get unblock;
  String get blockedNotice;

  // Invitations / added-me / favorites
  String get noInvitations;
  String get pending;
  String get favoritesTitle;

  // Groups
  String get groupsTitle;
  String get parentGroupLabel;
  String get noneOption;
  String get tabMyGroups;
  String get tabJoinable;
  String get myGroupsEmpty;
  String get joinableEmpty;

  /// FR-82: "Katılabileceklerim" satırında bu gruba nasıl dahil olunacağı.
  String get joinViaInvite;
  String get joinViaOpen;

  /// FR-81: özel grubun katılım bayrağı — yalnız grubu kuran üye belirler.
  /// Açık grup daveti DIŞLAMAZ: hem herkes katılabilir hem davet gönderilebilir.
  String get groupAccessLabel;
  String get openGroup;
  String get openGroupHint;
  String get closedGroup;
  String get closedGroupHint;

  /// Grup Bilgisi'ndeki erişim rozeti — tür ("Özel") değil, ERİŞİM yazar.
  String get accessOpenChip;
  String get accessClosedChip;
  String get openGroupToggleHint;
  String get organized;
  String get privateGroup;
  String get groupAdmin;

  /// Katılabileceklerim satırındaki kısa hali — "Yönetici: Ad Soyad".
  String get adminShort;
  String memberCount(int n);
  String get membersTitle;
  String get groupInfoTitle;
  String get openChat;
  String get leaveGroup;
  String get archiveGroup;
  String get archiveTitle;
  String get archiveEmpty;
  String get archiveHint;
  String get restore;
  String get removeMember;
  String get organizedJoinOnly;
  String get joinGroup;
  String get createGroupTitle;
  String get groupName;
  String get groupDescription;
  String get groupLogo;
  String get groupInviteMessage;
  String get inviteMembers;
  String get sendInvite;
  String inviteSyncSummary(int sent, int cancelled);
  String get joinedGroup;
  String get leftGroup;
  String get groupArchived;
  String get groupRestored;

  // Profile / settings
  String get profileTitle;
  String get editProfile;
  String get settingsTitle;
  String get adminSettingsTitle;
  String get account;
  String get visibility;
  String get visible;
  String get hidden;
  String get visibilityHint;
  String get addPolicyLabel;
  String get policyEveryone;
  String get policyApproval;
  String get addPolicyHint;
  String get blockedTitle;
  String get blockedEmpty;
  String get mutedTitle;
  String get mutedEmpty;
  String get language;
  String get switchTenant;
  String get switchTenantHint;
  String get logout;
  String get about;
  String get aboutBody;
  String get mute;
  String get unmute;
  String get you;
  String get privacyNote;
}

class _Tr extends AppStrings {
  const _Tr();

  @override
  String get appName => 'GroupConnect';
  @override
  String get tagline => 'Güvenli ve gizli kurumsal iletişim';

  @override
  String get ok => 'Tamam';
  @override
  String get cancel => 'İptal';
  @override
  String get save => 'Kaydet';
  @override
  String get apply => 'Uygula';
  @override
  String get send => 'Gönder';
  @override
  String get add => 'Ekle';
  @override
  String get selectAll => 'Hepsini Seç';
  @override
  String get clearSelection => 'Temizle';
  @override
  String contactsAddedSummary(int added, int invited) {
    if (added > 0 && invited > 0) {
      return '$added kişi eklendi · $invited davet gönderildi';
    }
    if (invited > 0) return '$invited davet gönderildi';
    return '$added kişi rehbere eklendi';
  }

  @override
  String get remove => 'Çıkar';
  @override
  String get delete => 'Sil';
  @override
  String get edit => 'Düzenle';
  @override
  String get done => 'Bitti';
  @override
  String get next => 'İleri';
  @override
  String get skip => 'Geç';
  @override
  String get search => 'Ara';
  @override
  String get join => 'Katıl';
  @override
  String get leave => 'Ayrıl';
  @override
  String get accept => 'Kabul Et';
  @override
  String get reject => 'Reddet';
  @override
  String get create => 'Yarat';
  @override
  String get all => 'Tümü';

  @override
  String get tabChats => 'Sohbetler';
  @override
  String get tabContacts => 'Kişiler';
  @override
  String get tabGroups => 'Gruplar';
  @override
  String get tabProfile => 'Profil';
  @override
  String get tabMenu => 'Menü';

  @override
  String get onbTitle1 => 'Yalnızca üyelere özel';
  @override
  String get onbBody1 =>
      'Kurumunuzun kapalı çevresinde, yalnızca yöneticinin tanımladığı kişilerle iletişim kurun.';
  @override
  String get onbTitle2 => 'Telefon numaranız gizli';
  @override
  String get onbBody2 =>
      'Kimseye telefon numaranızı vermeden, kurum dizini üzerinden kişileri keşfedin.';
  @override
  String get onbTitle3 => 'Uçtan uca güvenli';
  @override
  String get onbBody3 =>
      'Birebir ve grup metin mesajları uçtan uca şifrelenir. İçeriği yalnızca siz görürsünüz.';
  @override
  String get start => 'Başla';

  @override
  String get phoneTitle => 'Telefon Numarası';
  @override
  String get phoneSubtitle => 'Kayıtlı telefon numaranı gir';
  @override
  String get phoneHelp =>
      'Numaran sistemde kayıtlıysa bir doğrulama kodu (OTP) gönderilir.';
  @override
  String get continueLabel => 'Devam Et';
  @override
  String get otpTitle => 'Doğrulama Kodu';
  @override
  String otpSubtitle(String phone) =>
      '$phone numarasına gönderilen 6 haneli kodu gir';
  @override
  String get resend => 'Yeniden Gönder';
  @override
  String get otpError => 'Telefon numarası ya da OTP hatalı';
  @override
  String get verifying => 'Doğrulanıyor…';
  @override
  String get tenantSelectTitle => 'Kurum Seçin';
  @override
  String get tenantSelectSubtitle => 'İşlem yapmak istediğiniz kurumu seçiniz';
  @override
  String get rememberTenant => 'Tercihimi Hatırla';
  @override
  String get rememberTenantHint =>
      'Sonraki girişlerde doğrudan bu kuruma girilir '
      '(Menü → Kurum Değiştir ile değiştirilebilir).';

  @override
  String get profileSetupTitle => 'Profil Kurulumu';
  @override
  String get profileSetupHint =>
      'Kurum dizininde bu bilgilerle görüneceksin. Telefon numaran hiçbir yerde gösterilmez.';
  @override
  String get fullName => 'Ad Soyad';
  @override
  String get memberNo => 'Üye / Öğrenci No';
  @override
  String get department => 'Bölüm / Birim';
  @override
  String get role => 'Rol';
  @override
  String get course => 'Ders';

  @override
  String get chatsTitle => 'Sohbetler';
  @override
  String get chatsEmpty => 'Henüz sohbet yok';
  @override
  String get chatsEmptyHint =>
      'Kişi ekleyip mesajlaşmaya başla veya grup sohbetlerine göz at.';
  @override
  String get chatsFilterPersonal => 'Kişisel';
  @override
  String get chatsFilterEmpty => 'Bu filtrede sohbet yok';
  @override
  String get newChatTitle => 'Yeni Sohbet';
  @override
  String get messageHint => 'Mesaj yaz';
  @override
  String get reply => 'Yanıtla';
  @override
  String get copy => 'Kopyala';
  @override
  String get editedTag => 'düzenlendi';
  @override
  String get messageDeleted => 'Mesaj silindi';
  @override
  String get notInContactsYet =>
      'Henüz rehberinde değil — çevrimiçi bilgisi gösterilmez';
  @override
  String get introHint => 'Tanıtım mesajı yaz';
  @override
  String get today => 'Bugün';

  @override
  String get contactsTitle => 'Kişiler';
  @override
  String get everyoneTab => 'Herkes';
  @override
  String get myContactsTab => 'Rehberim';
  @override
  String get addedMeTab => 'Davetler';
  @override
  String get sentInvites => 'Gönderdiğim';
  @override
  String get approvedSection => 'Onaylananlar';
  @override
  String get contactsEmpty => 'Rehberin boş';
  @override
  String get contactsEmptyHint =>
      'Bir kişiyle iletişim kurmak için önce dizinde arayıp rehberine ekle.';
  @override
  String get addContact => 'Kişi Ekle';
  @override
  String get directoryTitle => 'Dizinde Ara';
  @override
  String get sortByName => 'Ada göre';
  @override
  String get sortByNumber => 'Numaraya göre';
  @override
  String get filterRole => 'Rol';
  @override
  String get filterDepartment => 'Bölüm';
  @override
  String get filterCourse => 'Ders';
  @override
  String get filterGroup => 'Grup';
  @override
  String get noResults => 'Sonuç bulunamadı';
  @override
  String get addToContacts => 'Rehbere Ekle';
  @override
  String get sendMessage => 'Mesaj Gönder';
  @override
  String get commonGroups => 'Ortak Gruplar';
  @override
  String get noCommonGroups => 'Ortak grup yok';
  @override
  String get removeFromContacts => 'Rehberden Çıkar';
  @override
  String addedDirectly(String name) => 'Rehbere Eklendi: $name';
  @override
  String removedFromContacts(String name) => 'Rehberden Çıkartıldı: $name';
  @override
  String get inviteSent => 'Davet gönderildi — onay bekleniyor';
  @override
  String get inviteMessageHint => 'Davet mesajı (opsiyonel)';
  @override
  String get favorite => 'Favori';
  @override
  String get addFavorite => 'Favorilere ekle';
  @override
  String get removeFavorite => 'Favorilerden çıkar';
  @override
  String get notes => 'Notlar';
  @override
  String get notesHint => 'Bu kişi hakkında not ekle';
  @override
  String get memberNoLabel => 'Üye No';
  @override
  String get roleLabel => 'Rol';
  @override
  String get departmentLabel => 'Bölüm';
  @override
  String get alreadyInContacts => 'Rehberinde';
  @override
  String get block => 'Engelle';
  @override
  String get unblock => 'Engeli Kaldır';
  @override
  String get blockedNotice => 'Bu kişiyi engelledin';

  @override
  String get noInvitations => 'Davetiye yok';
  @override
  String get pending => 'Bekliyor';
  @override
  String get favoritesTitle => 'Favoriler';

  @override
  String get groupsTitle => 'Gruplar';
  @override
  String get parentGroupLabel => 'Üst grup (isteğe bağlı)';
  @override
  String get noneOption => 'Yok (üst düzey)';
  @override
  String get tabMyGroups => 'Üye Olduklarım';
  @override
  String get tabJoinable => 'Katılabileceklerim';
  @override
  String get myGroupsEmpty => 'Henüz bir gruba üye değilsin';
  @override
  String get joinableEmpty => 'Katılabileceğin grup yok';
  @override
  String get joinViaInvite => 'Davet';
  @override
  String get joinViaOpen => 'Açık';
  @override
  String get groupAccessLabel => 'Katılım';
  @override
  String get openGroup => 'Açık Grup';
  @override
  String get openGroupHint =>
      'Kurumdaki herkes bulup davetsiz katılabilir. Ayrıca davet de gönderebilirsin.';
  @override
  String get closedGroup => 'Kapalı Grup';
  @override
  String get closedGroupHint => 'Yalnız davet ettiklerin katılabilir.';
  @override
  String get accessOpenChip => 'Açık Grup';
  @override
  String get accessClosedChip => 'Kapalı Grup';
  @override
  String get openGroupToggleHint => 'Kapatmak mevcut üyeleri çıkarmaz.';
  @override
  String get organized => 'Kurumsal';
  @override
  String get privateGroup => 'Özel';
  @override
  String get groupAdmin => 'Grup Yöneticisi';
  @override
  String get adminShort => 'Yönetici';
  @override
  String memberCount(int n) => '$n üye';
  @override
  String get membersTitle => 'Üyeler';
  @override
  String get groupInfoTitle => 'Grup Bilgisi';
  @override
  String get openChat => 'Sohbeti Aç';
  @override
  String get leaveGroup => 'Gruptan Ayrıl';
  @override
  String get archiveGroup => 'Grubu Arşivle';
  @override
  String get archiveTitle => 'Arşivlenmiş Gruplar';
  @override
  String get archiveEmpty => 'Arşivde grup yok';
  @override
  String get archiveHint =>
      'Arşivlenen grup herkesin listelerinden kalkar ama silinmez — mesajlarıyla birlikte durur. Buradan geri alabilirsin.';
  @override
  String get restore => 'Geri Al';
  @override
  String get removeMember => 'Çıkar';
  @override
  String get organizedJoinOnly =>
      'Kurumsal grup — üyelik yönetici tarafından belirlenir.';
  @override
  String get joinGroup => 'Gruba Katıl';
  @override
  String get createGroupTitle => 'Özel Grup Yarat';
  @override
  String get groupName => 'Grup Adı';
  @override
  String get groupDescription => 'Tanım / Açıklama';
  @override
  String get groupLogo => 'Logo (opsiyonel)';
  @override
  String get groupInviteMessage => 'Davet Mesajı';
  @override
  String get inviteMembers => 'Davet Et';
  @override
  String get sendInvite => 'Davet Gönder';
  @override
  String inviteSyncSummary(int sent, int cancelled) =>
      '$sent davet gönderildi · $cancelled iptal edildi';
  @override
  String get joinedGroup => 'Gruba katıldın';
  @override
  String get leftGroup => 'Gruptan ayrıldın';
  @override
  String get groupArchived => 'Grup arşivlendi';
  @override
  String get groupRestored => 'Grup geri alındı';

  @override
  String get profileTitle => 'Profil';
  @override
  String get editProfile => 'Profili Düzenle';
  @override
  String get settingsTitle => 'Ayarlar';
  @override
  String get adminSettingsTitle => 'Admin Ayarları';
  @override
  String get account => 'Hesap';
  @override
  String get visibility => 'Görünürlük';
  @override
  String get visible => 'Diğer Kişilere Görünür';
  @override
  String get hidden => 'Görünmez';
  @override
  String get visibilityHint =>
      'Görünmez olduğunda dizinde/aramada bulunamazsın.';
  @override
  String get addPolicyLabel => 'Rehbere Ekleme İzni';
  @override
  String get policyEveryone => 'Herkes Rehberine Ekleyebilir';
  @override
  String get policyApproval => 'Onayım Gerekir';
  @override
  String get addPolicyHint =>
      'Yalnız, admin matrisinin doğrudan görmediği kişiler için geçerlidir '
      '(ör. öğrenci → öğrenci). Doğrudan görenler her durumda ekleyebilir.';
  @override
  String get blockedTitle => 'Engellenenler';
  @override
  String get blockedEmpty => 'Engellenen kişi yok';
  @override
  String get mutedTitle => 'Sessize Alınanlar';
  @override
  String get mutedEmpty => 'Sessize alınan sohbet yok';
  @override
  String get language => 'Dil';
  @override
  String get switchTenant => 'Kurum Değiştir';
  @override
  String get switchTenantHint => 'Aktif kurumu değiştir';
  @override
  String get logout => 'Çıkış Yap';
  @override
  String get about => 'Hakkında';
  @override
  String get aboutBody =>
      'GroupConnect — kurum-içi güvenli iletişim uygulaması. Bu bir tıklanabilir prototiptir: veriler sahtedir, gerçek sunucu, ağ veya şifreleme yoktur.';
  @override
  String get mute => 'Sessize Al';
  @override
  String get unmute => 'Sesi Aç';
  @override
  String get you => 'Sen';
  @override
  String get privacyNote => 'Telefon numarası hiçbir ekranda gösterilmez.';
}

class _En extends AppStrings {
  const _En();

  @override
  String get appName => 'GroupConnect';
  @override
  String get tagline => 'Secure and private organizational messaging';

  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get apply => 'Apply';
  @override
  String get send => 'Send';
  @override
  String get add => 'Add';
  @override
  String get selectAll => 'Select all';
  @override
  String get clearSelection => 'Clear';
  @override
  String contactsAddedSummary(int added, int invited) {
    if (added > 0 && invited > 0) {
      return '$added added · $invited invited';
    }
    if (invited > 0) return '$invited invitation(s) sent';
    return '$added added to contacts';
  }

  @override
  String get remove => 'Remove';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get done => 'Done';
  @override
  String get next => 'Next';
  @override
  String get skip => 'Skip';
  @override
  String get search => 'Search';
  @override
  String get join => 'Join';
  @override
  String get leave => 'Leave';
  @override
  String get accept => 'Accept';
  @override
  String get reject => 'Reject';
  @override
  String get create => 'Create';
  @override
  String get all => 'All';

  @override
  String get tabChats => 'Chats';
  @override
  String get tabContacts => 'Contacts';
  @override
  String get tabGroups => 'Groups';
  @override
  String get tabProfile => 'Profile';
  @override
  String get tabMenu => 'Menu';

  @override
  String get onbTitle1 => 'Members only';
  @override
  String get onbBody1 =>
      'Communicate inside your organization’s closed circle — only with people the admin has defined.';
  @override
  String get onbTitle2 => 'Your phone stays private';
  @override
  String get onbBody2 =>
      'Discover people through the organization directory without sharing your phone number.';
  @override
  String get onbTitle3 => 'End-to-end secure';
  @override
  String get onbBody3 =>
      'One-to-one and group text messages are end-to-end encrypted. Only you can read them.';
  @override
  String get start => 'Get started';

  @override
  String get phoneTitle => 'Phone Number';
  @override
  String get phoneSubtitle => 'Enter your registered phone number';
  @override
  String get phoneHelp =>
      'If your number is registered, a verification code (OTP) is sent.';
  @override
  String get continueLabel => 'Continue';
  @override
  String get otpTitle => 'Verification Code';
  @override
  String otpSubtitle(String phone) =>
      'Enter the 6-digit code sent to $phone';
  @override
  String get resend => 'Resend';
  @override
  String get otpError => 'Phone number or OTP is incorrect';
  @override
  String get verifying => 'Verifying…';
  @override
  String get tenantSelectTitle => 'Select Organization';
  @override
  String get tenantSelectSubtitle =>
      'Choose the organization you want to use';
  @override
  String get rememberTenant => 'Remember My Choice';
  @override
  String get rememberTenantHint =>
      'Future logins go straight to this organization '
      '(change it via Menu → Switch Organization).';

  @override
  String get profileSetupTitle => 'Profile Setup';
  @override
  String get profileSetupHint =>
      'You will appear in the directory with this info. Your phone number is never shown.';
  @override
  String get fullName => 'Full Name';
  @override
  String get memberNo => 'Member / Student No';
  @override
  String get department => 'Department / Unit';
  @override
  String get role => 'Role';
  @override
  String get course => 'Course';

  @override
  String get chatsTitle => 'Chats';
  @override
  String get chatsEmpty => 'No conversations yet';
  @override
  String get chatsEmptyHint =>
      'Add a contact to start messaging, or browse your group chats.';
  @override
  String get chatsFilterPersonal => 'Personal';
  @override
  String get chatsFilterEmpty => 'No chats in this filter';
  @override
  String get newChatTitle => 'New Chat';
  @override
  String get messageHint => 'Type a message';
  @override
  String get reply => 'Reply';
  @override
  String get copy => 'Copy';
  @override
  String get editedTag => 'edited';
  @override
  String get messageDeleted => 'Message deleted';
  @override
  String get notInContactsYet =>
      'Not in your contacts yet — presence is hidden';
  @override
  String get introHint => 'Write an introduction message';
  @override
  String get today => 'Today';

  @override
  String get contactsTitle => 'Contacts';
  @override
  String get everyoneTab => 'Everyone';
  @override
  String get myContactsTab => 'My Contacts';
  @override
  String get addedMeTab => 'Invitations';
  @override
  String get sentInvites => 'Sent';
  @override
  String get approvedSection => 'Approved';
  @override
  String get contactsEmpty => 'Your contacts are empty';
  @override
  String get contactsEmptyHint =>
      'To reach someone, first find them in the directory and add them.';
  @override
  String get addContact => 'Add Contact';
  @override
  String get directoryTitle => 'Search Directory';
  @override
  String get sortByName => 'By name';
  @override
  String get sortByNumber => 'By number';
  @override
  String get filterRole => 'Role';
  @override
  String get filterDepartment => 'Department';
  @override
  String get filterCourse => 'Course';
  @override
  String get filterGroup => 'Group';
  @override
  String get noResults => 'No results found';
  @override
  String get addToContacts => 'Add to Contacts';
  @override
  String get sendMessage => 'Send Message';
  @override
  String get commonGroups => 'Common Groups';
  @override
  String get noCommonGroups => 'No common groups';
  @override
  String get removeFromContacts => 'Remove from Contacts';
  @override
  String addedDirectly(String name) => 'Added to Contacts: $name';
  @override
  String removedFromContacts(String name) => 'Removed from Contacts: $name';
  @override
  String get inviteSent => 'Invitation sent — awaiting approval';
  @override
  String get inviteMessageHint => 'Invitation message (optional)';
  @override
  String get favorite => 'Favorite';
  @override
  String get addFavorite => 'Add to favorites';
  @override
  String get removeFavorite => 'Remove from favorites';
  @override
  String get notes => 'Notes';
  @override
  String get notesHint => 'Add a note about this contact';
  @override
  String get memberNoLabel => 'Member No';
  @override
  String get roleLabel => 'Role';
  @override
  String get departmentLabel => 'Department';
  @override
  String get alreadyInContacts => 'In contacts';
  @override
  String get block => 'Block';
  @override
  String get unblock => 'Unblock';
  @override
  String get blockedNotice => 'You blocked this person';

  @override
  String get noInvitations => 'No invitations';
  @override
  String get pending => 'Pending';
  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get groupsTitle => 'Groups';
  @override
  String get parentGroupLabel => 'Parent group (optional)';
  @override
  String get noneOption => 'None (top level)';
  @override
  String get tabMyGroups => 'My Groups';
  @override
  String get tabJoinable => 'Can Join';
  @override
  String get myGroupsEmpty => 'You are not a member of any group yet';
  @override
  String get joinableEmpty => 'No groups to join';
  @override
  String get joinViaInvite => 'Invited';
  @override
  String get joinViaOpen => 'Open';
  @override
  String get groupAccessLabel => 'Access';
  @override
  String get openGroup => 'Open Group';
  @override
  String get openGroupHint =>
      'Anyone in the organization can find and join without an invite. You can still send invitations.';
  @override
  String get closedGroup => 'Closed Group';
  @override
  String get closedGroupHint => 'Only the people you invite can join.';
  @override
  String get accessOpenChip => 'Open Group';
  @override
  String get accessClosedChip => 'Closed Group';
  @override
  String get openGroupToggleHint => 'Closing it does not remove current members.';
  @override
  String get organized => 'Organized';
  @override
  String get privateGroup => 'Private';
  @override
  String get groupAdmin => 'Group Admin';
  @override
  String get adminShort => 'Admin';
  @override
  String memberCount(int n) => '$n members';
  @override
  String get membersTitle => 'Members';
  @override
  String get groupInfoTitle => 'Group Info';
  @override
  String get openChat => 'Open Chat';
  @override
  String get leaveGroup => 'Leave Group';
  @override
  String get archiveGroup => 'Archive Group';
  @override
  String get archiveTitle => 'Archived Groups';
  @override
  String get archiveEmpty => 'No archived groups';
  @override
  String get archiveHint =>
      'An archived group disappears from everyone\'s lists but is not deleted — it stays with its messages. You can restore it here.';
  @override
  String get restore => 'Restore';
  @override
  String get removeMember => 'Remove';
  @override
  String get organizedJoinOnly =>
      'Organized group — membership is set by the admin.';
  @override
  String get joinGroup => 'Join Group';
  @override
  String get createGroupTitle => 'Create Private Group';
  @override
  String get groupName => 'Group Name';
  @override
  String get groupDescription => 'Description';
  @override
  String get groupLogo => 'Logo (optional)';
  @override
  String get groupInviteMessage => 'Invitation Message';
  @override
  String get inviteMembers => 'Invite Members from Contacts';
  @override
  String get sendInvite => 'Send Invite';
  @override
  String inviteSyncSummary(int sent, int cancelled) =>
      '$sent invited · $cancelled cancelled';
  @override
  String get joinedGroup => 'Joined the group';
  @override
  String get leftGroup => 'You left the group';
  @override
  String get groupArchived => 'Group archived';
  @override
  String get groupRestored => 'Group restored';

  @override
  String get profileTitle => 'Profile';
  @override
  String get editProfile => 'Edit Profile';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get adminSettingsTitle => 'Admin Settings';
  @override
  String get account => 'Account';
  @override
  String get visibility => 'Visibility';
  @override
  String get visible => 'Visible to Others';
  @override
  String get hidden => 'Hidden';
  @override
  String get visibilityHint =>
      'When hidden, you cannot be found in the directory or search.';
  @override
  String get addPolicyLabel => 'Add-to-Contacts Permission';
  @override
  String get policyEveryone => 'Anyone Can Add Me';
  @override
  String get policyApproval => 'My Approval Required';
  @override
  String get addPolicyHint =>
      'With approval required, people must wait for your approval before adding you.';
  @override
  String get blockedTitle => 'Blocked';
  @override
  String get blockedEmpty => 'No blocked people';
  @override
  String get mutedTitle => 'Muted';
  @override
  String get mutedEmpty => 'No muted conversations';
  @override
  String get language => 'Language';
  @override
  String get switchTenant => 'Switch Organization';
  @override
  String get switchTenantHint => 'Change the active organization';
  @override
  String get logout => 'Log Out';
  @override
  String get about => 'About';
  @override
  String get aboutBody =>
      'GroupConnect — secure in-organization messaging. This is a clickable prototype: data is mock, with no real server, network or encryption.';
  @override
  String get mute => 'Mute';
  @override
  String get unmute => 'Unmute';
  @override
  String get you => 'You';
  @override
  String get privacyNote => 'Phone numbers are never shown on any screen.';
}

/// Convenience accessor: `context.s.chatsTitle`.
extension StringsContext on BuildContext {
  AppStrings get s => AppStrings.of(AppScope.of(this).language);

  /// Dile duyarlı BÜYÜK HARF — bölüm başlıkları için.
  ///
  /// Dart'ın [String.toUpperCase] metodu dil bilmez: Türkçede `i` harfini `I`
  /// yapar ("Favoriler" → "FAVORILER"), oysa doğrusu `İ`dir ("FAVORİLER").
  /// Küçük `ı` → `I` dönüşümü zaten doğru olduğundan ek işlem gerekmez.
  String upper(String text) =>
      AppScope.of(this).language == AppLanguage.tr
          ? text.replaceAll('i', 'İ').toUpperCase()
          : text.toUpperCase();
}
