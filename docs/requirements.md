# GroupConnect — Gereksinim ve Kullanım Senaryosu Dokümanı

- Belge durumu: Revize (rev. 2) — insan onayı bekliyor
- Aşama: A-SDLC / requirements-analyst çıktısı
- Kaynaklar: `_sources/description-extract.txt` (kavram/tanım dokümanı), `_sources/ppt-flow-extract.txt` (55 slaytlık akış destesi)
- Not: Bu belge, iki kaynak taslağın **kilitli kararlar** doğrultusunda uzlaştırılmış halidir. Kaynaklardaki tutarsızlıklarda kilitli kararlar geçerlidir. rev. 2'de dört açık madde (ekler, varsayılan görünürlük, rehbere-ekleme asimetrisi, ikincil özellikler) karara bağlanmıştır (bkz. Bölüm 7). Kod, mimari ve UI tasarımı bu belgenin kapsamı dışındadır; benimsenen teknolojiler yalnızca NFR kısıtı olarak kaydedilmiştir (detay tasarım mimarın işidir).

---

## 1. Problem Tanımı / Vizyon

GroupConnect; bir organizasyon içindeki kişilerin **kapalı devre**, **güvenli** ve **gizli** biçimde iletişim kurmasını sağlayan, **çok kiracılı (multi-tenant)** genel amaçlı bir iletişim platformudur. Aynı uygulama farklı tipteki organizasyonlar tarafından kullanılabilir; roller kiracıya göre yapılandırılabilir:

- **Üniversite** — roller: akademisyen, öğrenci
- **Site (konut sitesi)** — roller: idari personel, ev sahibi, sakin
- **Dernek** — roller: yönetici, idari personel, üye

Üniversite senaryosu belge boyunca yalnızca örnekleme amacıyla kullanılmaktadır.

### Çözülen problemler

Mevcut organizasyon-içi iletişim yöntemleri aşağıdaki eksiklikleri barındırmaktadır; GroupConnect bunları hedef alır:

1. **E-posta ve web tabanlı iletişimin etkisizliği:** Duyurular çoğu kez hiç okunmaz veya geç fark edilir; zaman-kritik bilgiler (örn. ders iptali) amacına ulaşmaz.
2. **LMS/duyuru sistemlerinin anlık iletişime uygun olmaması:** Materyal paylaşımı için uygundur ama hızlı, çift yönlü, birebir iletişimi doğal biçimde desteklemez.
3. **Telefon numarası paylaşma zorunluluğu:** Hızlı iletişim için personel/akademisyen kişisel numarasını paylaşmak zorunda kalır; bu, gizlilik (privacy) ihlali ve uygunsuz kanal açılması demektir.
4. **Kurumsal olmayan anlık iletişim uygulamalarının (WhatsApp/Telegram vb.) dezavantajları:** Veriler kurum kontrolü dışındaki sunucularda tutulur, telefon numarası zorunludur, erişim denetimi zayıftır, kurumsal hiyerarşiye (bölüm/ders/grup) uygun yapı kurulamaz, dışlanan kişiler oluşur, kimlik doğrulama garanti edilemez, dış sağlayıcıya bağımlılık ve düzenleme uyumsuzluğu (KVKK/GDPR) riski doğar.

### Vizyon ifadesi

Organizasyon üyelerinin **yalnızca yöneticinin tanımladığı kişilerden oluşan** kapalı bir çevrede, **telefon numaralarını veya kişisel e-postalarını paylaşmadan**, **uçtan uca şifreli** biçimde hızlı ve gizli iletişim kurabileceği; sunucunun ve yöneticinin mesaj içeriğini **hiçbir koşulda göremediği**; kişilerin birbirini kurum-içi bir dizin üzerinden (telefon görünmeden) keşfedebildiği; kurumsal hiyerarşiye uygun **organize gruplar** ile kişiye özel **özel gruplar**ın bir arada bulunduğu bir platform.

---

## 2. Aktörler / Roller

| Aktör | Yüzey | Açıklama |
|---|---|---|
| **Üye (Member)** | Mobil uygulama | Organizasyona kayıtlı son kullanıcı. Kiracıya özgü bir role sahiptir (örn. akademisyen/öğrenci, personel/sakin, yönetici/üye). Roller kiracı yapılandırmasıyla belirlenir. |
| **Grup Yöneticisi (Group Admin)** | Mobil uygulama | Özel (bireysel) grup oluşturan üye. Yalnızca oluşturduğu grup(lar) kapsamında yönetim yetkilerine sahiptir. Ayrı bir kullanıcı türü değil, üyenin bir bağlam-içi rolüdür. |
| **Organizasyon Yöneticisi (Organization Admin)** | Web admin paneli | Bir kiracının (organizasyonun) yöneticisi. Üye ve organize grup tanımlar, kiracı tercihlerini belirler. Mesaj içeriğine **erişemez**. |
| **Sistem/Platform Yöneticisi (System Admin)** | (Asgari / ertelenmiş) | Kiracıların (organizasyonların) oluşturulması ve platform seviyesi işletim. MVP kapsamında **asgari** tutulur; ayrıntılı yetki modeli Açık Sorular'a bırakılmıştır. |

---

## 3. Kapsam ve Yüzeyler (Surfaces)

GroupConnect üç ayrı teslimat yüzeyinden oluşur:

1. **Mobil uygulama (üye-yönelik):** Flutter, tek kod tabanı, iOS + Android. E2E anahtarların üretildiği ve mesajların yalnızca cihaz üzerinde çözüldüğü istemci.
2. **Web admin paneli (yönetici-yönelik):** React. Kiracı kurulumu, üye/grup provizyonu, kiracı tercihleri. Mesaj içeriğine erişimi yoktur.
3. **Backend + E2E anahtar-dizini sunucusu:** Node.js/TypeScript + WebSocket. Yalnızca **şifreli mesaj zarfları (ciphertext) + meta veri**, genel anahtar/prekey dizini, kullanıcı/kiracı/grup/üyelik kayıtlarını tutar.

### MVP sınırı

- **Yalnızca metin sohbeti** (1:1 ve grup).
- Sesli/görüntülü arama **kapsam dışı** (Faz-2).
- ERP/LMS/SIS entegrasyonu **yok**.
- Web admin paneli **kapsam içi**.

---

## 4. Fonksiyonel Gereksinimler (FR)

FR'ler test edilebilir olacak şekilde modüllere göre gruplanmıştır.

### 4.1. Kimlik Doğrulama ve Katılım (Authentication & Onboarding)

- **FR-1:** Uygulama açılışında bir karşılama/tanıtım (splash) ekranı gösterilir; kullanıcı tanıtımı geçebilir. Tanıtım/onboarding yalnızca ilk kurulumda gösterilir, sonraki girişlerde gösterilmez.
- **FR-2:** Girişin tek yöntemi **telefon numarası + SMS OTP**'dir. E-posta ile giriş **desteklenmez**.
- **FR-3:** Kullanıcı telefon numarasını ülke koduyla girer; numara uzunluğu ilgili ülkenin (country code, min/max uzunluk) kurallarına göre doğrulanır. Desteklenen ülkeler kiracı/sistem tarafından yapılandırılabilir.
- **FR-4:** OTP yalnızca girilen telefon numarasıyla eşleşen bir üye varsa gönderilir. Numara sistemde yoksa OTP gönderilmez; **kullanıcıya bu durum sızdırılmaz** — hata mesajı ancak OTP girişinden sonra ve genel biçimde ("Telefon numarası ya da OTP hatalı") verilir.
- **FR-5:** OTP yeniden gönderiminde artan bekleme süreleri uygulanır (örn. 1. ve 2. denemede kısa, sonrasında kademeli artan; süreler kiracı-yapılandırılabilir admin parametreleridir). Belirli sayıda (örn. 5) hatalı denemeden sonra hesap kilitlenir ve yalnızca yönetici müdahalesiyle açılır (`userlocked` sıfırlama).
- **FR-6:** Tüm basamaklar girildiğinde OTP otomatik doğrulanır. OTP doğruysa: kullanıcı tek kiracıya kayıtlıysa doğrudan uygulamaya, birden çok kiracıya kayıtlıysa **kiracı seçim ekranına** yönlendirilir.
- **FR-7:** Bir telefon numarası birden çok organizasyona (kiracıya) üye olabilir. Kullanıcı uygulamayı bir kez kurar; her organizasyon için ayrı bir bağlamda çalışır. Kiracılar arası kullanım **birbirinden tamamen yalıtılmıştır**.
- **FR-8:** Kullanıcı bir menü seçeneği ile aktif kiracıyı (kurumu) değiştirebilir; bu seçenek yalnızca birden çok kiracıya kayıtlı kullanıcılarda görünür.
- **FR-9:** İlk başarılı girişte kullanıcı profil kurulum ekranına yönlendirilir (bkz. 4.7).
- **FR-10:** İlk girişte kullanıcının cihazında E2E anahtar malzemesi (kimlik anahtarı, imzalı prekey, tek-kullanımlık prekey seti) **üretilir**; **yalnızca genel (public) anahtarlar/prekey'ler** sunucudaki anahtar-dizinine yayınlanır. Özel anahtarlar cihazdan hiçbir zaman çıkmaz.
- **FR-11:** Uygulama arayüz dili en az **Türkçe ve İngilizce** destekler; kiracı için hangi dillerin sunulacağını yönetici belirler.

### 4.2. Organizasyon Dizini ve Kullanıcı Keşfi (Directory & User Discovery)

- **FR-12:** Her kiracı için, yönetici tarafından provizyonlanan bir **organizasyon üye dizini (Directory)** her zaman mevcuttur. Bu dizin, kişisel iletişim listesinden (Kişilerim/Rehber, bkz. 4.3) ayrıdır.
- **FR-13:** Kullanıcı, dizinde **Ad-Soyad**, **Üye/Öğrenci No** ve **Bölüm/Birim** bilgileriyle arama (pattern matching) yapabilir.
- **FR-14:** Arama sonuçları **rol** (örn. akademisyen/öğrenci), **bölüm/birim**, **ders** ve **grup** kriterlerine göre filtrelenebilir; ada göre veya numaraya göre sıralanabilir. "Numaraya göre arama" seçeneğinin açık/kapalı olması ve etiketi kiracı-yapılandırılabilir bir admin tercihidir.
- **FR-15:** Arama ve keşif sonuçlarında kullanıcının **telefon numarası hiçbir koşulda gösterilmez**. Kullanıcılar dizinde yöneticinin atadığı görünür kimlik ve organizasyon bilgileriyle (ad-soyad, üye no, bölüm, rol) temsil edilir.
- **FR-16:** Kullanıcı diğer kullanıcılara **görünür (visible)** veya **görünmez (hidden)** olacağını Ayarlar'dan seçebilir. Görünmez bir kullanıcı, keşif/aramada bulunamaz.
- **FR-17:** Yeni oluşturulan bir kullanıcının **varsayılan görünürlüğü** (opt-out=varsayılan görünür / opt-in=varsayılan görünmez) **kiracı bazında bir admin ayarıdır**. Bu ayar yalnızca **kullanıcı oluşturma anında** uygulanır; yönetici ayarı sonradan değiştirse bile mevcut kullanıcılara **geriye dönük uygulanmaz**. Yönetici bu ayarı açıkça seçmezse **sistem varsayılanı GÖRÜNÜR (opt-out)**'tur.
- **FR-18:** Kullanıcı, başka bir kullanıcıyı **engelleyebilir (block)**. Alice, Bob'u engellediğinde: Bob, keşifte Alice'i bulamaz ve Alice ile mesajlaşamaz; Bob doğrudan erişmeye çalışırsa uygulama "kullanıcı bulunamadı" davranışı gösterir. Engelleme **kişi bazlıdır** ve tek yönlüdür.
- **FR-19:** MVP'de görünürlük modeli **yalnızca görünür/görünmez + kişi bazlı engelleme** ile sınırlıdır. Bölüm/ders/seçili-kişi bazlı granüler görünürlük Faz-2'dir (bkz. Kapsam Dışı).

### 4.3. Kişilerim / Rehber (Personal Contacts)

- **FR-20:** Kişisel iletişim listesi (Kişilerim/Rehber) her kullanıcı için **boş** başlar. (Dizin her zaman dolu olsa da, kişisel rehber ayrıdır ve boştur.)
- **FR-21:** Bir kişiyle iletişim kurmak için kullanıcı önce o kişiyi keşif (4.2) ile bulup **davet/kabul** akışıyla rehberine ekler.
- **FR-22:** Rehbere ekleme, ilgili kişinin rehbere-ekleme politikasına göre yürür: onay gerektirmeyen kişiler doğrudan eklenir, onay gerektiren kişiler için **davet gönderme → alıcının onaylaması** akışı işler ve yalnızca onaylayan kişi eklenir (rol-bazlı politika için bkz. FR-23).
- **FR-23:** Rehbere ekleme yetkisi **rol-bazlı, kiracı-yapılandırılabilir** bir politikadır ("Herkes / Onaylı"): **akademisyenler (yetkili rol) keşif sonrası doğrudan** rehbere eklenebilir; **öğrenciler (temel rol)** ancak **ilgili kişinin onayıyla** eklenebilir. Varsayılan politika kiracı ayarından gelir; kullanıcı kendi tercihini bu çerçevede belirleyebilir (bkz. FR-52).
- **FR-24:** Bir kişi rehbere eklendiğinde şu bilgiler görüntülenir: görünür kimlik/erişim bilgisi, ad-soyad, üye/öğrenci no, bölüm ve rehber sahibinin eklediği notlar. **Telefon numarası gösterilmez.**
- **FR-25:** Rehber iki sekme (tab) içerir: **Kişi Kayıtları** ve **Grup Kayıtları**. Grup kayıtları, kullanıcının üyesi olduğu grupları listeler.
- **FR-26:** Kullanıcı bir kişiyi rehberinden çıkarabilir. Bir kişi verdiği onayı iptal ettiğinde, karşı taraftaki erişim bilgisi rehberden silinir (diğer bilgilerinin kayıtta kalıp kalmayacağı tasarım aşamasında netleştirilecektir).
- **FR-27:** Kullanıcı, kendisini rehberine ekleyenleri görebilir ("Beni Rehberlerine Ekleyenler") ve izin verdiği kişileri karşılıklı olarak kendi rehberine ekleyebilir.
- **FR-28:** Kullanıcı, kendisine gelen **üyelik/rehber davetiyelerini** listeleyip kabul/ret edebilir.

### 4.4. Birebir (1:1) Metin Sohbeti

- **FR-29:** Kullanıcı, rehberindeki bir kişiyle **gerçek zamanlı metin mesajlaşması** yapabilir.
- **FR-30:** Tüm 1:1 mesajlar **uçtan uca şifrelidir** (Signal Protocol, Double Ratchet). Şifre çözme yalnızca gönderici ve alıcı cihazlarında gerçekleşir.
- **FR-31:** Alıcı çevrimdışıysa mesajlar sunucuda **şifreli zarf (ciphertext) olarak** saklanır ve alıcı çevrimiçi olduğunda iletilir (store-and-forward). Sunucu içeriği **çözemez**.
- **FR-32:** İlk kez mesaj gönderilen (henüz rehberde olmayan) bir kişiye, keşif ekranından tanıtım mesajı gönderilebilir; bu durumda karşı tarafın çevrimiçi/rehber bilgileri gösterilmeyebilir (rehberde olmadığından).
- **FR-33:** Sohbet **kesinlikle yalnızca metindir**. Görsel/dosya/konum ekleri (attachment) **kapsam dışıdır — kesinleşmiştir**. (Akış destesindeki galeri/kamera/konum ikonları uygulanmayacaktır.)

### 4.5. Gruplar (Groups)

Tek terim kullanılır: **Grup**. İki türü vardır. "Kulüp/Community/Oda" adlandırmaları kullanılmaz; MVP'de grup-içi oda (room) **yoktur**.

**Organize Grup (yönetici tarafından yönetilen):**

- **FR-34:** Organize Gruplar yalnızca **Organizasyon Yöneticisi** tarafından oluşturulur (örn. bölüm, ders, tüm öğrenciler, ev sahipleri grubu vb.).
- **FR-35:** Organize Grup üyeliği yönetici tarafından belirlenir; üyeler **kendiliğinden katılamaz/ayrılamaz**.
- **FR-36:** Kullanıcının dahil olduğu organize gruplar, ilk kurulumda rehberdeki grup sekmesine eklenir ve kalıcıdır.

**Özel (Bireysel) Grup (üye tarafından oluşturulan):**

- **FR-37:** Herhangi bir üye bir **Özel Grup** oluşturabilir ve o grubun **Grup Yöneticisi** olur.
- **FR-38:** Grup Yöneticisi, rehberindeki kişilere davet gönderir; **davet edilenlerden kabul edenler** gruba dahil olur.
- **FR-39:** Bir üye üyesi olduğu bir Özel Gruptan **dilediği zaman ayrılabilir**.
- **FR-40:** Grup Yöneticisi, dilediği üyeyi gruptan **çıkarabilir** ve grubu **silebilir**.
- **FR-41:** Özel Grup oluşturma sırasında en az şu bilgiler girilir: grup adı, tanım/açıklama, (opsiyonel) logo, davet mesajı. Grubu oluşturan otomatik olarak ilk üye ve yöneticidir.

**Ortak grup davranışı:**

- **FR-42:** Kullanıcı, grupları iki başlık altında görebilir: **Üye Olduklarım** ve **Katılabileceklerim**.
- **FR-43:** Grup içi mesajlaşma **uçtan uca şifrelidir** ve grup şifreleme mekanizması olarak **Sender Keys** kullanılır. Sunucu grup mesaj içeriğini **çözemez**.
- **FR-44:** Grup mesajları çevrimdışı üyeler için şifreli zarf olarak saklanır ve teslim edilir (store-and-forward).
- **FR-45:** Rehberdeki bir kişiyle "ortak grup" oluşturma başlatıldığında, ilgili kişi yeni grubun ilk üyesi olarak otomatik dahil edilir.

### 4.6. Bildirimler (Notifications)

- **FR-46:** Kullanıcıya anlık **push bildirimleri** gönderilir (Android: FCM, iOS: APNs).
- **FR-47:** Push bildirimleri **mesaj içeriği taşımaz**; yalnızca "yeni mesaj/olay var" düzeyinde içeriksiz tetikleyici bilgi taşır. İçerik yalnızca uygulama içinde, cihazda şifre çözüldükten sonra görüntülenir.
- **FR-48:** Bildirim tetikleyen olay türleri en az şunlardır: yeni birebir mesaj, yeni grup mesajı, yeni grup oluşturma/davet, rehber/üyelik davetiyesi, sistem bildirimleri. (Grup mesajlarında bildirim davranışının ayrıntısı tasarım aşamasında netleştirilecektir.)
- **FR-49:** Kullanıcı grup/sohbet bazında bildirimleri **sessize alabilir (mute)**.

### 4.7. Profil ve Gizlilik Ayarları (Profile & Privacy)

- **FR-50:** Kullanıcı, kendi profilini görüntüleyip düzenleyebilir. Zorunlu asgari alanlar: telefon no (internal, gösterilmez), ad-soyad, kategori/rol. *(Nickname ve Motto gibi ek alanların dahil olup olmayacağı Açık Sorular'dadır.)*
- **FR-51:** Kullanıcı, keşifte görünürlüğünü (görünür/görünmez) ayarlayabilir (bkz. FR-16, FR-19).
- **FR-52:** Kullanıcı, kendisini rehbere eklemeye ilişkin izin politikasını ("Herkes" / "Onaylı") ayarlayabilir (bkz. FR-23). Politika kiracı varsayılanıyla uyumludur.
- **FR-53:** Kullanıcı, engellediği kişilerin listesini görüntüleyip yönetebilir.
- **FR-54:** Kullanıcı **favori kişiler** tanımlayabilir/çıkarabilir (favoriler hızlı erişim listesidir). Favoriler **MVP kapsamındadır**.

### 4.8. Web Admin Paneli (Organization Admin)

- **FR-55:** Organizasyon Yöneticisi, web admin paneli üzerinden kiracı (organizasyon) kurulumunu yapar: kiracı bilgileri, rol modeli yapılandırması, dil seçenekleri.
- **FR-56:** Kullanıcılar **yalnızca yönetici tarafından** tanımlanır; **kendi kendine kayıt (self sign-up) yoktur**.
- **FR-57:** Yönetici kullanıcıları iki yolla ekler: (a) **Excel/toplu içe aktarım** (bulk import), (b) **manuel web formu**. Asgari kullanıcı alanları: telefon no, ad-soyad, kategori/rol; ayrıca üye/öğrenci no, bölüm gibi dizin alanları.
- **FR-58:** Yönetici bir kullanıcının görünür kimliğini ve dizin alanlarını atar/düzenler; yönetici kullanıcıyı **kaldırabilir (removal)**.
- **FR-59:** Kullanıcı durum (status) modeli en az şu değerleri destekler: **invited** (tanımlandı, henüz giriş yapmadı), **active** (aktif), **pending-request** (Faz-2 katılım talebi için ayrılmış), **removed** (kaldırıldı). Model, Faz-2 "katılım talebi → yönetici onayı" akışını sonradan destekleyecek şekilde tasarlanmalıdır.
- **FR-60:** Yönetici **Organize Grupları** oluşturur ve üyeleri gruplara atar (bölüm/ders/rol bazlı organize gruplar dahil).
- **FR-61:** Yönetici, kiracı tercihlerini belirler; en az: **varsayılan görünürlük politikası** (opt-in/opt-out, yalnızca oluşturma anında geçerli, seçilmezse varsayılan görünür — FR-17), dil seçenekleri, OTP zamanlama/kilitleme parametreleri (FR-5), "numaraya göre arama" seçeneği (FR-14), "rehbere ekleme yetkisi" rol-bazlı varsayılanı (FR-23).
- **FR-62:** Yönetici, sistemin erişim/kullanım kayıtlarını (loglar) ve performans/sağlık verilerini **yalnızca meta veri düzeyinde** izleyebilir. Yönetici **hiçbir mesaj içeriğine erişemez** (bkz. NFR-2).

---

## 5. Fonksiyonel Olmayan Gereksinimler (NFR)

- **NFR-1 (E2E Şifreleme):** Tüm mesaj içerikleri **uçtan uca şifrelenir**. Protokol **Signal Protocol**'dür: 1:1 için Double Ratchet, gruplar için Sender Keys. Sunucu yalnızca **şifreli mesaj zarfı (ciphertext) + meta veri** saklar.
- **NFR-2 (Sunucu/Yönetici içeriği okuyamaz):** Ne backend sunucusu ne de web admin paneli mesaj içeriğini **hiçbir koşulda** çözemez/okuyamaz. Bu, mimari ve depolama tasarımının değiştirilemez kısıtıdır.
- **NFR-3 (Tek cihaz):** Sistem **yalnızca tek cihaz (single device)** destekler. Çoklu cihaz senkronizasyonu yoktur.
- **NFR-4 (Kurtarma yok):** **Anahtar yedeği ve kurtarma yoktur.** Kullanıcı cihazını kaybederse mesaj geçmişi kalıcı olarak kaybolur; bu davranış açıkça kabul edilmiştir.
- **NFR-5 (Telefon gizliliği):** Kullanıcının telefon numarası yalnızca kimlik doğrulama için internal kullanılır; **başka hiçbir kullanıcıya hiçbir ekranda gösterilmez**.
- **NFR-6 (Çok kiracılılık ve yalıtım):** Sistem çok kiracılıdır; kiracılar arası veri (kullanıcı, grup, üyelik, mesaj zarfı, dizin, ayarlar) **kesin biçimde yalıtılmalıdır**. Bir kullanıcının farklı kiracılardaki kullanımı birbirinden bağımsızdır.
- **NFR-7 (Platform):** Mobil uygulama **Flutter** ile tek kod tabanında **iOS + Android** olarak geliştirilir. Web admin paneli **React** ile geliştirilir.
- **NFR-8 (Backend ve veri katmanı):** Backend **Node.js/TypeScript + WebSocket** üzerinedir. Kayıt sistemi (system of record) **PostgreSQL**'dir (kullanıcılar, kiracılar, gruplar, üyelikler, şifreli mesaj zarfları + meta veri, genel-anahtar/prekey dizini, kiracı ayarları). **Redis**, bağlantı kaydı (connection registry), OTP ve hız sınırlama (rate-limit) için kullanılır.
- **NFR-9 (Gerçek zamanlılık ve çevrimdışı):** Mesaj teslimi gerçek zamanlıdır (WebSocket). Alıcı çevrimdışıyken şifreli zarflar saklanır ve çevrimiçi olduğunda teslim edilir.
- **NFR-10 (Push gizliliği):** Push bildirimleri (FCM/APNs) **hiçbir mesaj içeriği taşımaz**.
- **NFR-11 (Yalnızca metin):** MVP yalnızca metin iletişimini kapsar; ses/görüntü/ek kapsam dışıdır.
- **NFR-12 (Ölçeklenebilirlik):** Sistem, büyük organizasyonları ve potansiyel olarak büyük grupları desteklemelidir. Çok büyük "yayın tipi" grupların Sender Keys maliyeti dikkate alınmalıdır (bkz. Açık Sorular; tek yönlü yayın adayı Faz-2).
- **NFR-13 (Anti-spam / hız sınırlama):** OTP gönderiminde kademeli bekleme ve deneme kilidi uygulanır (FR-5). Numara doğrulanmadan içerik/sistem bilgisi sızdırılmaz.
- **NFR-14 (Mahremiyet ve mevzuat uyumu):** Sistem, kişisel verilerin korunmasına ilişkin düzenlemelere (KVKK/GDPR) uyacak şekilde, "privacy by design" ilkesiyle tasarlanır. Telefon numarası değişikliği log ile kayıt altına alınır.
- **NFR-15 (Yerelleştirme):** Arayüz en az Türkçe ve İngilizce'yi destekler; ülke/telefon-formatı meta verisi (country code, bayrak, min/max uzunluk) veritabanında tutulur.

---

## 6. Açıkça Kapsam Dışı (Out of Scope)

Aşağıdaki maddeler MVP kapsamı dışındadır. Bir kısmı Faz-2 adayıdır.

1. **Sesli ve görüntülü aramalar** — Faz-2.
2. **ERP / LMS / SIS entegrasyonu** (Moodle, öğrenci bilgi sistemi, otomatik grup oluşturma vb.) — kapsam dışı.
3. **"Mark" (işaretleme) özelliği** — tamamen düşürüldü.
4. **Kullanıcıya görünen "access-code" (erişim kodu) kavramı** — düşürüldü; keşif dizin üzerinden yapılır.
5. **Çoklu cihaz (multi-device)** — kapsam dışı.
6. **Anahtar yedeği / kurtarma (key backup/recovery)** — kapsam dışı (kayıp = geçmiş kaybı).
7. **Grup-içi odalar (rooms-within-groups)** — kapsam dışı.
8. **Granüler görünürlük** (bölüm/ders/seçili kişi bazlı görünürlük) — Faz-2.
9. **Self-servis katılım talebi (request-to-join → admin onayı)** — Faz-2 (durum modeli buna hazır tutulur, FR-59).
10. **MLS (Messaging Layer Security)** — büyük gruplar için olası Faz-2 alternatifi; MVP'de yok.
11. **E-posta ile giriş** — düşürüldü.
12. **Anket (Poll) modülü** — kaynak akış destesinde bulunan bu modül kilitli MVP kararlarında yer almamaktadır; Faz-2 adayı olarak kayıt altına alınmıştır (bkz. Açık Sorular).
13. **Görsel/dosya/konum ekleri (attachments)** — kapsam dışı; sohbet yalnızca metindir (FR-33).
14. **Okundu bilgisi (read receipts) / "kim okudu" bilgisi** — Faz-2.
15. **Çevrimiçi durumu (presence) göstergesi** — Faz-2.

---

## 7. Varsayımlar ve Açık Sorular

Yalnızca yapıyı (build) maddi olarak etkileyen açık maddeler listelenmiştir. Kaynaklardaki çok sayıda küçük "gerekli mi? / hangisi?" sorusu bilinçli olarak dışarıda bırakılmıştır.

### 7.1. Bu revizyonda karara bağlananlar (ÇÖZÜLDÜ)

- **ÇÖZÜLDÜ — Ekler:** Sohbet **kesinlikle yalnızca metin**; görsel/dosya/konum eki yok. (FR-33, NFR-11, Kapsam Dışı #13)
- **ÇÖZÜLDÜ — Varsayılan görünürlük:** Yönetici opt-in/opt-out seçmediğinde **sistem varsayılanı GÖRÜNÜR (opt-out)**. (FR-17, FR-61)
- **ÇÖZÜLDÜ — Rehbere ekleme asimetrisi:** Akademisyen (yetkili rol) doğrudan, öğrenci (temel rol) onayla; **rol-bazlı, kiracı-yapılandırılabilir** politika. (FR-22, FR-23, FR-52)
- **ÇÖZÜLDÜ — İkincil özellikler:** Favoriler **MVP'de** (FR-54); **okundu bilgisi** ve **çevrimiçi durumu** **Faz-2 / kapsam dışı** (Kapsam Dışı #14, #15).

### 7.2. Kalan açık maddeler

1. **Çok büyük "yayın tipi" gruplar:** "Tüm öğrenciler" gibi çok büyük gruplar Sender Keys maliyeti göz önüne alınınca nasıl ele alınacak? (Aday: yalnızca yönetici→üye **tek yönlü yayın**, Faz-2.)
2. **Mesaj dışa aktarımı / ekran görüntüsü koruması:** Mesajların dışa aktarımı engellenecek mi; ekran görüntüsü (screenshot) koruması istenecek mi?
3. **Profil alanları:** Nickname ve Motto gibi alanlar profile dahil mi? Görünür kimlik alan seti kesinleştirilmeli (bkz. FR-50).
4. **System/Platform Admin kapsamı:** Sistem yöneticisinin yetki sınırları, kiracı yaşam döngüsü yönetimi MVP'de ne kadar detaylandırılacak? (Şimdilik asgari.)
5. **Ad-hoc çok kişili "geçici grup":** Bir kişinin anlık olarak birden çok kişiyle mesajlaşması için ayrı bir "geçici grup" yapısına ihtiyaç var mı? — **Muhtemelen Faz-2.**
6. **Eşzamanlı çoklu kiracı oturumu:** Kullanıcı aynı anda birden çok kiracıya login olabilir mi, yoksa aktif kiracıdan çıkmadan diğerine geçemez mi? (Kaynak Soru-23.) — **Varsayım: aynı anda tek aktif kiracı.**
7. **Anket (Poll) modülü:** Akış destesindeki Anket modülü MVP kapsamına alınacak mı, yoksa Faz-2 mi? — **Varsayım: Faz-2 (kapsam dışı).**
8. **Nihai ürün adı:** Ürün adı çalışma-adı olarak **GroupConnect** kalmaktadır; nihai ad sonra kesinleştirilecektir. (Kaynaklarda "Campus Connect / CC" çalışma adı geçmektedir.)

---

*Belge sonu — inceleme için hazır.*
