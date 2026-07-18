# GroupConnect — Üye Uygulaması (Tıklanabilir UI Prototipi)

Bu klasör, **GroupConnect** projesinin üye-yönelik mobil uygulamasının
**tıklanabilir arayüz prototipidir**. Amacı, gerçek uygulama yazılmadan önce
UX/gereksinimlerin doğrulanmasıdır: tüm ekranlar gezilebilir, tüm butonlar/satırlar
gerçekten ilgili sayfaya gider.

> **Önemli:** Bu bir **mock-veri** prototipidir.
> - Gerçek **backend / ağ (network) YOK**.
> - **Uçtan uca şifreleme (E2E) YOK** — kimlik doğrulama sahtedir.
> - OTP adımında **herhangi bir 6 haneli kod** kabul edilir.
> - Tüm veriler bellekte (in-memory) tutulur; uygulama yeniden başlatıldığında sıfırlanır.
> - Arayüz **Türkçe**dir; Ayarlar'dan **TR/EN** diline geçilebilir.
>
> Bu UI, gerçek uygulamanın ön yüzü olarak **yeniden kullanılmak** üzere temiz
> yazılmıştır (domain modelleri + `AppState` durum katmanı ekranlardan ayrıktır;
> mock veriyi gerçek servislerle değiştirmek yeterlidir).

## Gereksinimler

- Flutter **3.29.3** (Dart 3.7.2). PATH'e ekleyin:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH"
  ```
- Harici paket bağımlılığı **yok** (sadece Flutter SDK + `cupertino_icons`).
  Durum yönetimi, çerçeve-içi `InheritedNotifier` ile yapılır.

## Çalıştırma

Tarayıcıda (Chrome / web — önerilen inceleme yöntemi):

```bash
cd app
flutter run -d chrome
```

iOS simülatöründe:

```bash
cd app
open -a Simulator                 # simülatörü aç
flutter devices                   # simülatör kimliğini gör
flutter run -d "iPhone 17 Pro"    # ya da: flutter run -d <simulator-id>
```

Derlemeyi doğrulama:

```bash
flutter analyze        # temiz geçer
flutter build web      # başarıyla derlenir → build/web
```

## Nasıl gezilir (hızlı tur)

1. **Splash** açılır (3 sn sonra otomatik ilerler ya da "Geç").
2. **Tanıtım** (onboarding) — 3 sayfa, geçilebilir (yalnızca ilk açılışta).
3. **Telefon** — ülke kodu + numpad ile numara girin, "Devam Et".
4. **OTP** — herhangi 6 hane girin (otomatik doğrulanır).
5. **Kurum Seçin** — bu telefon iki kuruma kayıtlı (çok-kiracılı):
   **Ege Üniversitesi** ya da **Yeşil Vadi Sitesi**.
6. Üniversiteyi seçerseniz **Profil Kurulumu** açılır (ilk giriş) → "Bitti".
7. **Ana kabuk** (alt sekmeler): Sohbetler · Kişiler · Gruplar · Profil.
   - **Kişiler / Kişi Kayıtları** sekmesi **boş** başlar → "Kişi Ekle" → **Dizinde Ara**.
   - **Gruplar** ve **grup sohbetleri** örnek mesajlarla doludur (organize gruplar
     ilk kurulumda otomatik eklenir).
   - **Ayarlar → Kurum Değiştir** ile iki kurum arasında geçiş yapıp verilerin
     tamamen yalıtıldığını görebilirsiniz.

## Ekran listesi

Kimlik / katılım
- Splash / tanıtım (onboarding)
- Telefon numarası girişi (ülke kodu + numpad)
- OTP girişi (6 hane, otomatik doğrulama)
- Çoklu-kiracı kurum seçimi
- İlk giriş profil kurulumu

Sohbetler
- Sohbet listesi (grup + 1:1 birleşik)
- 1:1 metin sohbeti (yalnızca metin; ek/kamera/konum ikonu YOK)

Kişiler / Rehber
- Kişi Kayıtları (boş durum) + Grup Kayıtları sekmeleri
- Dizinde arama/keşif (ad-soyad / üye-no / bölüm; rol/bölüm/ders/grup filtreleri; ada/numaraya sıralama)
- Kişi detay (mesaj gönder, rehbere ekle/çıkar, engelle, favori, ortak gruplar, ortak grup yarat, not)
- Rehbere ekleme akışı (akademisyen doğrudan / öğrenci onaylı davet)
- Davetiyeler (Gelen/Giden — kabul/ret)
- Beni Rehberlerine Ekleyenler (karşılıklı ekle)
- Favoriler

Gruplar
- Üye Olduklarım / Katılabileceklerim sekmeleri
- Grup detay + üye yönetimi (çıkar / ayrıl / sil)
- Grup metin sohbeti
- Özel Grup Yarat (ad, tanım, logo-ops., davet mesajı, rehberden üye davet)
- Organize gruplar salt-görüntüleme/katılım (yönetici yönetir)

Profil / Ayarlar
- Profil görüntüle/düzenle (ad-soyad, üye no, bölüm, rol)
- Ayarlar: görünürlük (görünür/görünmez), rehbere ekleme izni (Herkes/Onaylı),
  engellenenler, sessize alınanlar (mute), dil (TR/EN), Kurum Değiştir, Hakkında, Çıkış

## Klasör yapısı

```
lib/
  main.dart                     # giriş
  app.dart                      # MaterialApp + faz-tabanlı kök yönlendirme (RootGate)
  theme/app_theme.dart          # Material 3 indigo/mavi tema
  i18n/strings.dart             # TR/EN yerelleştirme (dil değiştirilebilir)
  models/
    enums.dart                  # MemberVisibility, AddPolicy, GroupType, InviteKind ...
    models.dart                 # Role, Tenant, Member, Message, Group, Invitation
  state/
    app_scope.dart              # InheritedNotifier (bağımlılık-siz DI)
    app_state.dart              # ChangeNotifier — tüm iş mantığı ve mutasyonlar
    tenant_data.dart            # kiracı-başı yalıtılmış veri adası (NFR-6)
    mock_data.dart              # sahte veri (2 kiracı, kullanıcılar, gruplar, mesajlar)
  widgets/
    common.dart                 # avatar, boş-durum, etiket, zaman biçimi
    numpad.dart                 # telefon/OTP numpad'i
    chat_widgets.dart           # baloncuk, mesaj listesi, yalnızca-metin yazım kutusu
  screens/
    onboarding/                 # splash, onboarding
    auth/                       # phone, otp, tenant-select, profile-setup
    shell/home_shell.dart       # alt navigasyon
    chats/                      # sohbet listesi, 1:1 sohbet
    contacts/                   # rehber, dizin arama, kişi detay, davetiyeler, eklenenler, favoriler
    groups/                     # grup listesi, detay, sohbet, yaratma, üyeler, kişi seçici
    profile/                    # profil, düzenle, ayarlar, engellenenler, sessize alınanlar
```

## Gereksinim izlenebilirliği (özet)

Kod, gereksinim kimliklerine (FR-#/NFR-#) yorumlarla bağlanmıştır. Öne çıkanlar:

- **Yalnızca metin** (FR-33, NFR-11): sohbet yazım kutusunda ek/kamera/konum ikonu yok.
- **Telefon gizli** (FR-15, FR-24, NFR-5): hiçbir ekranda telefon numarası gösterilmez.
- **Rehber boş başlar** (FR-20) ve keşif→davet/onay ile dolar (FR-21..FR-23).
- **Favoriler** MVP kapsamında (FR-54); **okundu/presence** yok (Kapsam Dışı #14, #15).
- **Anket / grup-içi oda YOK** (Kapsam Dışı #12, #7).
- **Çok-kiracılı yalıtım** (FR-7, FR-8, NFR-6): kurum değiştirince tüm veri adası değişir.
