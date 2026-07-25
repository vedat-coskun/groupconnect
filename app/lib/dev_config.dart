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

/// Oto-giriş kimliği: telefonun SON İKİ HANESİ kullanıcıyı seçer (01 = Vedat,
/// akademisyen). Bkz. MockData.identities.
const String kDevAutoLoginPhone = '5555555501';

/// Oto-giriş kurumu. 'uni' = Atlas Üniversitesi.
const String kDevAutoLoginTenant = 'uni';
