# GroupConnect — Admin Ayarları (Kurum Yönetici Panosu)

Her **tenant (kurum)** yöneticisinin web admin panelinden yapılandıracağı
ayarların tek kaynağı. Prototip/gereksinim aşamasında burada tutulur; gereksinim
dondurulurken ilgili FR'lere işlenir. "Admin ayarlarını listele" dendiğinde bu
belge esas alınır.

---

## Ayar değişim kategorileri

Her ayarın bir **değişim/kilit semantiği** vardır: (a) değişiklik kullanıcıya ne
zaman yansır, (b) kullanım başlayınca değiştirilebilir mi. **Not:** prototip
backend'siz olduğundan değişiklikler anında görünür; aşağıdaki kategoriler
**gerçek sürümdeki** davranışı tanımlar.

| Kategori | Ne zaman yansır | Kullanım sonrası |
|---|---|---|
| 🟢 **Canlı** | Sonraki senkron/açılışta | Her zaman değiştirilebilir; ileriye dönük (geçmiş eylemler durur) |
| 🟡 **Yeni-öğeye** | Yalnız bundan sonra oluşturulan öğelere | Değiştirilebilir; mevcutlar korunur |
| 🔴 **Kullanım-öncesi** | Kurulumda | Kullanım başlayınca kilitlenir / kısıtlanır |
| ⚫ **Kalıcı** | Kurulumda | Hiç değişmez (yapısal; şu an listede yok) |

---

## 1. Görünürlük varsayılanı  _(mevcut karar)_
- **Kategori:** 🟡 Yeni-öğeye — mevcut üyeler kendi seçimini korur; yeni kayıtlar yeni varsayılanı alır.
- **Kapsam:** tenant geneli.
- **Değer:** `opt-out` (varsayılan GÖRÜNÜR) | `opt-in` (varsayılan GÖRÜNMEZ).
- **Sistem varsayılanı:** `opt-out` — herkes görünür başlar.
- Kullanıcı kendi **Görünür / Görünmez** geçişini her zaman yapabilir (bu KALIR).

## 2. Grup hiyerarşisi  _(yeni)_
- **Kategori:** derinlik (`maxDepth`) 🔴 **Kullanım-öncesi** (gruplar oluşunca kilit / yalnız güvenli yönde artırılabilir); seviye adları 🟢 **Canlı**.
- **Kapsam:** tenant geneli — **yalnız KURUMSAL (organize) gruplar için**.
- **Önemli:** Hiyerarşiyi **yalnız admin** tanımlar (kurumsal gruplar zaten admin
  tarafından oluşturulur). **Özel gruplar DÜZDÜR** — hiyerarşi yoktur, üyeler
  oluşturur ve hiçbir zaman üst gruba bağlanmaz. Üye uygulamasında hiyerarşi
  **salt-okur** gezilir (Gruplar → Kurum Yapısı).
- **Üyelik yalnız EN ALT seviyede:** ara/üst seviye gruplara **doğrudan üye
  atanmaz**. Bir üst grubun kişileri = **alt gruplarının kişilerinin toplamı**
  (ör. Fakülte = Bölüm1 + Bölüm2). Ekranda üst grup açılınca önce **alt gruplar**,
  sonra bu **toplam kişi listesi** gösterilir; sayılar birbirini tutar.
- `maxDepth`: kurumun kullanacağı seviye sayısı — admin panelden **parametrik**
  seçilir: `1` = düz (alt grup yok), `2`, `3`. Varsayılan **2**.
  - Model **N seviye** destekler; sunulan üst sınır (`3`) yalnızca bir **politika
    parametresi**dir — özel bir kurum için yükseltmek kod değil ayar değişikliğidir.
- `levelLabels`: her seviyenin **kuruma özel adı**.
  - Üniversite → L1 "Dekanlık/Fakülte", L2 "Bölüm".
  - Spor kulübü → L1 "Branş" (voleybol), L2 "Takım" (büyük erkek / büyük kadın / U18).
  - Site / Dernek → çoğu zaman tek seviye yeterli (`maxDepth = 1`).
- **Model notu:** gruplar `parentGroupId` ile **serbest derinlikte ağaç**;
  UI yalnızca var olan seviyeleri gösterir. Tek seviyeli kurum düz liste görür,
  fazladan seviye dayatılmaz. İleride 3. seviye gerekirse yalnız o tenant'ın
  `maxDepth` değeri artırılır — **şema/kod değişmez**.

## 3. Doğrudan Görme ve Ekleme matrisi  _(rev.3 sonrası: §3 + eski §4'ün YERİNİ ALDI)_
- **Kategori:** 🟢 Canlı — sonraki görme/eklemelerde geçerli; geçmiş eklemeler durur.
- **Kapsam:** **rol × rol matrisi, kurum geneli.** Admin her rol için işaretler:
  *"Bu rol, şu rolleri **doğrudan görür**."* Görme ve sormadan ekleme **tek
  kavramdır** — A rolü B'yi doğrudan görüyorsa:
  - B'nin üyeleri A'nın **Kişiler → HERKES** sekmesinde listelenir (dizin),
  - A onları **onaysız ve bildirimsiz** rehberine ekler; **rehbere eklemeden
    doğrudan mesaj da atabilir** (HERKES satırı → sohbet),
  - hedefin bireysel "görünmez" ayarına **bakılmaz** (kurumsal görünürlük
    matris kararıdır — aşağıdaki bilinçli sonuç bölümü aynen geçerlidir).
- **İşaretli OLMAYAN çiftlerde** (ör. öğrenci → öğrenci): hedef kurum dizininde
  **görünmez**; kişi ancak **paylaşılan bağlamdan** (grup üye listesi, Kurum
  Yapısı) bulunur ve ekleme **karşı tarafın onayıyla** olur (Kişiler → DAVETLER).
- **Örnek (üniversite):** İdari ve Akademisyen → herkesi görür; Öğrenci →
  yalnız İdari + Akademisyen'i görür (öğrenci→öğrenci onaylıdır). Varsayılan:
  yetkili roller herkesi, temel roller yalnız yetkili rolleri görür.
- **Tarihçe:** rev.3'teki "Sormadan Ekleme yetkisi" (rol başına tek bayrak) ile
  eski §4 "Rehbere ekleme politikası" (hedef rol başına Doğrudan/Onaylı) **aynı
  soruyu iki ayrı yerden cevaplıyordu** ve çelişebiliyordu; kurum sahibi kararı
  ile tek matriste birleştirildi. Aşağıdaki "bilinçli sonuç" bloğu o karardan
  devralınmıştır ve geçerliliğini korur.

### Bilinçli sonuç — "görünmez", matriste seni gören role karşı işlemez
Bu, **kasıtlı bir mahremiyet ödünü**dür; hata değildir, geri çevrilmemelidir:
- Bir öğrenci kendini "görünmez" yapsa bile matriste öğrenciyi gören her rol
  (ör. her akademisyen) onu dizinde görür ve **sessizce** rehberine ekleyebilir.
- Eklenen kişiye **bildirim gitmez**, hiçbir yüzeyde iz kalmaz (bkz. FR-27 iptali).
- **Gerekçe (kurum sahibi kararı):** akademisyen–öğrenci yetki asimetrisi zaten
  vardır; eklemeyi öğrenciden gizlemek ona güç kazandırmaz, yalnız gürültü üretir.
- **Not:** matris modeliyle birlikte bireysel "Görünür/Görünmez" ayarının kalan
  işlevi **belirsizleşmiştir** (matris-dışı çiftler birbirini zaten görmez).
  "Görünme / Erişilebilme" ayrımı tasarım gündemindedir — karara bağlanana dek
  üye ayarı arayüzde durur ama davranışa etkisi yoktur.

## 4. _(boş — eski "Rehbere ekleme politikası" §3'teki matrise KATILDI)_
Rol başına "Doğrudan/Onaylı" seçimi artık ayrı bir ayar değildir: matriste
işaretli çift = doğrudan, işaretsiz çift = onaylı. Bölüm numarası, atıflar
kaymasın diye korunmuştur.

## 5. Roller  _(yeni)_
- **Rol çeşidi / seti** (hangi roller var, kaç tane, yetki bayrağı):
  **Kategori 🔴 Kullanım-öncesi** — kurulumda **bir kez** belirlenir; kurum
  kullanılmaya başlayınca rol TÜRÜ eklenip çıkarılamaz.
- **Rol adları** (etiketler): **Kategori 🟢 Canlı** — her zaman değiştirilebilir
  ve **dile göre** (TR/EN) yeniden belirlenir. Ad değişikliği kimliği/yetkiyi
  değiştirmez, yalnız görünen etiketi.

## 6. _(boş — grup "açık/kapalı" bayrağı buraya AİT DEĞİL)_
Bu belge **kurum yöneticisinin** panosudur. Grubun "açık / kapalı" (davetsiz
katılınabilir) bayrağı bir admin ayarı **değildir**:
- **Kurumsal gruplarda böyle bir bayrak yoktur.** Üyeliği baştan sona yönetici
  belirler; davet de, bireysel katılma da, ayrılma da yoktur (FR-35).
- Bayrak **yalnız özel gruplara** aittir ve onu **grubu kuran üye** (grubun kendi
  admin'i) belirler — kurum yöneticisi değil. Bu yüzden burada değil, gereksinim
  belgesinde tanımlıdır (FR-81/FR-82).

_(rev.3 ara taslağında bu bölüm "yönetici kurumsal grubu açık işaretler" diye
yazılmıştı — **hatalıydı**, kaldırıldı. Bölüm numarası, §1–§5'e yapılan atıflar
kaymasın diye korunmuştur.)_
