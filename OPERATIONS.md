# DSYS Operasyon Rehberi

## Gözlemlenebilirlik

- Uygulama hata kayıtları `AppErrorReporter` üzerinden toplanır.
- Mobil platformlarda Crashlytics etkinse framework ve platform hataları Firebase Crashlytics'e gönderilir.
- Web ortamında hata kaydı debug log ile tutulur.
- Gemini OCR kullanımı için uygulama `--dart-define=GEMINI_API_KEY=...` ile başlatılmalıdır.

## Güvenlik Hijyeni Rutini

Her release öncesi aşağıdaki kontroller uygulanır:

1. `grep -RInE "password|secret|api[_-]?key|token|private_key" . --exclude-dir=.git`
2. `flutter pub outdated`
3. `.gitignore`, `SECURITY.md`, `firestore.rules` gözden geçirilir.
4. GitHub Actions secret'larının güncelliği doğrulanır.

## Rollback Prosedürü

1. Son başarılı production artifact'ı (`web-build`, `android-release-apk`, `ios-release-app`) bulun.
2. Firebase Hosting için son kararlı commit SHA'sı checkout edilip `DSYS CI/CD` workflow'u yeniden tetiklenir.
3. Mobil dağıtım için son başarılı tag yeniden yayınlanır veya ilgili artifact mağaza yüklemesine geri alınır.
4. Crashlytics ve kullanıcı geri bildirimleri 30 dakika boyunca izlenir.
5. Olay sonrası kök neden analizi BACKLOG veya issue kaydı ile belgelenir.

## Olay Yönetimi

- Kritik hata: giriş, veri kaydı veya belge üretimi engelleniyorsa rollback tetiklenir.
- Orta seviye hata: tek modül etkileniyorsa feature flag / erişim kısıtlama uygulanır.
- Düşük seviye hata: bir sonraki bakım sürümüne planlanır.
