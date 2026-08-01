/// Geliştirme kısayolları — prototipi elden geçirirken hızlandırıcılar.
///
/// **Yalnız DEBUG derlemede etkilidir**: her kullanım `kDebugMode` ile
/// sarılır, bu yüzden release/production'a asla sızmaz. Gerçek onboarding/giriş
/// akışını test etmek istersen [kDevAutoLogin]'i `false` yap.
library;

/// Açıkken uygulama açılışta onboarding + telefon + OTP + kurum seçimini
/// ATLAYIP doğrudan ana ekrana (Sohbetler) düşer. Her build'de 4-5 dokunuş
/// tasarrufu. Gerçek akışı denemek için `false` yap.
const bool kDevAutoLogin = true;

/// Oto-giriş kimliği: telefonun SON İKİ HANESİ kullanıcıyı seçer. Bkz.
/// MockData.identities: 01 = Vedat (akademisyen), 02 = Suden (öğrenci),
/// 03 = Arda (öğrenci). Öğrenci seçilince davet/onay akışı denenebilir —
/// öğrenci, matrisin doğrudan görmediği birini (ör. başka bir öğrenci)
/// eklediğinde "Beklemede" davet oluşur (akademisyen herkesi doğrudan ekler).
const String kDevAutoLoginPhone = '5555555503';

/// Oto-giriş kurumu. 'uni' = Atlas Üniversitesi.
const String kDevAutoLoginTenant = 'uni';
