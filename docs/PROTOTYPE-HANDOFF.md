# GroupConnect — Basit Sürüm İçin Devir (Handoff) Dokümanı

> **Amaç:** Bu dosya, GroupConnect prototipinin **basitleştirilmiş bir sürümünü**
> ayrı/yeni bir oturumda hazırlarken gereken tüm bağlamı tek yerde toplar. Tam
> ve resmî kaynak `docs/requirements.md`'dir (rev.4, ~480 satır); bu dosya onun
> **özet + en güncel karar tadilatları**dır. Çelişkide `requirements.md` +
> aşağıdaki "rev.5 tadilatları" geçerlidir.
>
> Son güncelleme: 2026-08-06.

---

## 0. Nerede ne var (mutlak yollar)

Depo: `/Users/vedatcoskun/groupconnect` (kendi git repo'su; `a-sdlc-demo`'nun
**kardeşi**, iç içe değil). Uzak: `github.com/vedat-coskun/groupconnect` (private).

- `docs/requirements.md` — **resmî gereksinim belgesi** (rev.4 ONAYLI, FR-1…FR-100).
- `docs/admin-settings.md` — kiracı admin ayarlarının tek kaynağı.
- `docs/GroupConnect_Universite_2026-07-19.xlsx`, `..._Site_...xlsx` — örnek kurum verileri.
- `_sources/description-extract.txt` — kavram/tanım dokümanı (özgün fikir).
- `_sources/ppt-flow-extract.txt` — 55 slaytlık akış destesi.
- `app/` — Flutter tıklanabilir-prototip (Material 3, backend YOK).
  - `lib/state/app_state.dart` — TÜM iş mantığı + tek bellek-içi veri deposu (ChangeNotifier).
  - `lib/state/mock_data.dart` — kurumlar, roller, üyeler, gruplar, mesaj seed'i.
  - `lib/state/admin_settings.dart`, `lib/state/tenant_data.dart` — ayar/kiracı modeli.
  - `lib/models/` — Member, Group, Message, Invitation, enum'lar.
  - `lib/screens/` — ekranlar; `lib/widgets/common.dart` — paylaşımlı "kutu" bileşenleri.
  - `lib/i18n/strings.dart` — TR/EN metinler.
  - `lib/dev_config.dart` — SADECE prototip geliştirme kısayolları (aşağıda).
  - `test/` — 44 widget/birim testi.

---

## 1. Ürün tek cümlede

**GroupConnect**, bir organizasyonun (üniversite / site / dernek …) üyelerinin,
**telefon numarası paylaşmadan**, **kapalı devre** ve (hedefte) **uçtan uca
şifreli** biçimde iletişim kurmasını sağlayan **çok kiracılı (multi-tenant)** bir
mesajlaşma/rehber uygulamasıdır. Sunucu ve yönetici mesaj içeriğini göremez;
kişiler birbirini kurum-içi bir **dizin** üzerinden (telefon görünmeden) keşfeder.

Çözdüğü sorunlar: e-posta/LMS'in anlık iletişime uygun olmaması, kişisel numara
paylaşma zorunluluğu, WhatsApp/Telegram'ın kurum-dışı/denetimsiz/KVKK-riskli olması.

---

## 2. Aktörler / roller (kiracıya göre parametrik)

- **Üniversite:** akademisyen, öğrenci
- **Site:** personel (idari), ev sahibi, sakin
- **Dernek:** yönetici, personel, üye

Roller **yetkili (authority)** olabilir (ör. akademisyen/personel/yönetici): yetkili
roller dizinde herkesi otomatik görür ve onaysız ekler. Rol adları admin tarafından
düzenlenebilir.

---

## 3. Çekirdek model (basit sürümde de korunmalı olan öz)

### 3.1 Görünürlük — matris bir VARSAYILANdır, ENGEL değil (FR-21 rev.5 — ÖNEMLİ)
- Admin bir **rol-çifti matrisi** tanımlar (`directRolesByRole`, Admin → "Otomatik
  Görme ve Ekleme"): işaretli çiftler birbirini **otomatik** görür (dizinde, kişisel
  ayardan bağımsız) ve **onaysız** ekler.
- İşaretsiz çiftlerde: karşı taraf kendini **"Görünür"** tutuyorsa görünür ama ekleme
  **onay davetiyle** olur. **"Tamamen gizli" YOKTUR** — herkes en az kendi ayarıyla
  görünebilir; matris yalnızca *yeni kişi keşfini* kısıtlar, var olan rehberi değil.
- `everyoneVisible` = (matris-görünen) ∪ (kendini "Görünür" tutanlar); tek dışlanan:
  matris-dışı **ve** "Görünmez" olan.
- **Rehber ⊆ Herkes:** gizli bir rehber kişisi bile "Herkes"te ve yeni-sohbet
  pikerinde kalır (`everyoneVisibleOrContact`).
- **Rol-başına görünürlük KİLİDİ (2026-08-06):** admin bir rolü kilitlerse o rolün
  üyeleri Profil'de kendi görünürlük/ekleme ayarını **göremez**; etkin görünürlük admin
  varsayılanına sabitlenir (`effectiveVisibility`, `visibilityLockedRoleIds`).

### 3.2 Rehber/davet — 3 seçenekli kabul, aktif/pasif
- **Ekleme (`addContact`):** matris-doğrudan ya da politika "everyone" ise **anında
  AKTİF** ekler; değilse **onay daveti** (giden) oluşturur.
- **Davet edilenin yanıtı 3 seçenek:** **Reddet** / **Çift yönlü kabul** / **Tek yönlü
  kabul**.
  - Kabulde **davet EDEN her zaman karşıyı AKTİF alır** (tekrar-davet döngüsü biter).
  - **Çift yönlü** → kabul eden de karşıyı **AKTİF** alır.
  - **Tek yönlü** → kabul eden karşıyı yalnız **PASİF** alır (onayladım ama eklemedim).
- **Aktif/Pasif ayrımı:** doğrudan eklediğim + davet edip kabul edilen + çift-yönlü
  kabul = **AKTİF**; tek-yönlü kabul = **PASİF** (`passiveIds`). Rehberim ekranında
  "Rehberim / + Pasif" geçişi, pasif satırda "Pasif" rozeti.

### 3.3 Gruplar
- **Kurumsal gruplar:** üyeliği **yalnız yönetici** kurar; davet/katılma/ayrılma **yok**.
  Hiyerarşik olabilir (Fakülte→Bölüm…), derinlik admin-parametrik (`maxDepth` 1–3).
  Yaprak gruba üyelik tüm atalara üyelik sayılır (türetilmiş üyelik).
- **Özel gruplar:** üye kendi kurar; "Herkese Açık" yaparsa kiracı üyeleri davetsiz
  katılabilir; "Kapalı" ise davetle.
- **Görme ≠ yazma (FR-90):** her grupta **manager + iki anahtar** (görünürlük: tüm
  üyeler / yalnız yetkili; yazma: yalnız manager / üyeler de). Üye olmak sohbet
  erişimi için *gerekli ama yeterli değil*.
- **Arşivleme** var, **silme yok** (FR-91/92).

### 3.4 Sohbetler ekranı
- **"HEPSİ"** bölümü = **gelen kutusu**: yalnız en az bir mesajı olan sohbetler, düz
  liste, **son mesaj önizlemesi + saat**, son aktiviteye göre sıralı (FR-100 rev.5).
- **Kategori bölümleri** (Kurumsal/Özel/Kişisel) = **dizin**: üye olunan her grup
  (mesajsız dahi), içerik/saat **yok**, alfabetik. (Gizlilik: içerik yalnız bilinçle
  açılan HEPSİ'de yüzeye çıkar.)

### 3.5 Diğer sabit kararlar
- Kişiler ekranı üç sekme: **HERKES · REHBERİM · DAVETLER** (FR-88).
- "Tercihimi Hatırla" (FR-87): sonraki girişte kurum seçimini atlar.
- Favoriler = sabitleme; tek ortak kişi-listesi.
- İkinci onay yok (NFR-18).

---

## 4. Admin (Web-Admin'in prototip yüzeyi) — `admin-settings.md`
- Görünürlük varsayılanı (opt-in/opt-out) + rol-başına kilit.
- Grup hiyerarşi derinliği (1–3) ve seviye adları.
- Rol adları; "Otomatik Görme ve Ekleme" matrisi.
- **Görünüm (appearance):** vurgu rengi / yazı boyutu / yazı tipi — her eksende admin
  varsayılanı + **kilit**; kilitli değilse kullanıcı kendine göre değiştirebilir.
- Kurum logosu (kurum seçim ekranında).

---

## 5. Teknik notlar (mevcut prototip)
- Flutter + Material 3; durum yönetimi **InheritedNotifier (`AppScope`) + ChangeNotifier
  (`AppState`)**; **backend yok**, tüm veri tek bellek-içi depoda.
- Kişisel durum (rehber/favori/engel/görünüm) kimlik başına **SharedPreferences** blob'una
  yazılır (`flutter.gc_user_<tenant>_<myId>`); mock veri (grup/mesaj) her açılışta sıfırlanır.
- "Kutu kutu" (boxy/kart) tasarım dili app-geneli (paylaşımlı bileşenler
  `widgets/common.dart`: `BoxedTabBar`, `CountBox`, `InfoBox`, `BoxedPageHeader`,
  `_BoxedNavBar`). Kullanıcı bu dili + Outlook-tarzı çoklu seçimi seviyor.

### Yalnız-prototip geliştirme kısayolları (gerçek sürümde KALDIRILACAK)
`lib/dev_config.dart` (hepsi `kDebugMode` ile sarılı, release'e sızmaz):
- **Oto-giriş** (`kDevAutoLogin`): onboarding/telefon/OTP/kurum akışını atlar; kimlik
  telefonun son 2 hanesiyle seçilir (01=Vedat akademisyen, 02=Suden öğrenci,
  03=Arda öğrenci).
- **"User" (Demo) sekmesi** (debug'da en soldaki): tek simülatörde iki-kişilik akış
  testi için kimliği anında değiştirir. İçinde **"Normal giriş akışını dene"** butonu
  gerçek telefon/OTP akışına döner; uygulama yeniden açılınca yine oto-girişe düşer.

---

## 6. Basit sürüm için öneri (neyi tut / neyi bırak)

**Çekirdek (tut):** çok-kiracılı kimlik + roller; dizin/görünürlük (matris=varsayılan);
rehber + 3-seçenekli davet (aktif/pasif); 1:1 ve grup sohbeti; kurumsal vs özel grup
ayrımı; telefon paylaşmama ilkesi.

**Basitleştirmek için bırakılabilir (ilk sürümde):** grup hiyerarşi derinliği >1
(tek seviye yeter); görme≠yazma iki-anahtar inceliği; appearance kilit/override
sistemi; arşivleme; "HEPSİ vs kategori" ikili liste mantığı (tek düz sohbet listesi
yeter); rol-başına görünürlük kilidi. Bunlar zenginleştirmedir, çekirdek değil.

**Karar verirken:** çelişki olursa `requirements.md` + bu dosyanın rev.5 tadilatları
(3.1, 3.2, 3.4) geçerlidir. Emin değilsen kullanıcıya sor — tahmin etme.
