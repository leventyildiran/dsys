# DSYS Release Rehberi

## Web Release

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test --coverage
flutter build web --release
```

`DSYS CI/CD` workflow'u main branch üzerinde web build ve Firebase Hosting deploy işlemini yapar.

## Android Paketleme

```bash
flutter build apk --release
```

GitHub Actions içindeki `DSYS Mobile Release` workflow'u `build/app/outputs/flutter-apk/app-release.apk` artifact'ını üretir.

## iOS Paketleme

```bash
flutter build ios --release --no-codesign
```

`DSYS Mobile Release` workflow'u `Runner.app` artifact'ını üretir; mağaza yüklemesi öncesinde codesign aşaması ayrıca uygulanır.

## Dağıtım Kontrolü

- [ ] `MODULE_ACCEPTANCE.md` kontrol listesi gözden geçirildi.
- [ ] `OPERATIONS.md` rollback adımları teyit edildi.
- [ ] Crashlytics ve CI artifact'ları kontrol edildi.
- [ ] Güvenlik hijyeni taraması yapıldı.
