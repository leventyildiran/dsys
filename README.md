# 🏛️ DSYS — Döner Sermaye Yönetim Sistemi

Uşak Üniversitesi Döner Sermaye İşletme Müdürlüğü için geliştirilen danışmanlık takip, hakediş hesaplama ve karar belgesi üretim sistemidir.

## 🚀 Canlı

**Web:** [https://dsys-44b8e.web.app](https://dsys-44b8e.web.app)

## 🏗️ Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| Frontend | Flutter (Web + Android + iOS) |
| Backend | Firebase (Auth, Firestore, Hosting) |
| State Management | Provider + Selector |
| Routing | GoRouter (auth-aware redirect) |
| Mimari | Clean Architecture (Presentation → Domain → Data) |

## 📁 Proje Yapısı

```
lib/
├── core/              # Hesaplama motoru, karar metni servisi, Türkçe format
├── models/            # Dart veri modelleri (Firestore ↔ App)
├── providers/         # ChangeNotifier state yönetimi
├── screens/           # UI ekranları (dashboard, login, modül ekranları)
├── services/          # Firestore CRUD servisleri
├── firebase_options.dart
├── main.dart
├── router.dart
└── theme.dart
```

## 🛠️ Kurulum

```bash
# Bağımlılıkları yükle
flutter pub get

# Gemini OCR ile çalıştır
flutter run -d chrome --dart-define=GEMINI_API_KEY=your-key

# Web'de çalıştır
flutter run -d chrome

# Analiz
flutter analyze

# Test
flutter test
```

## 📋 Geliştirme Durumu

Detaylı backlog ve faz takibi için → [BACKLOG.md](BACKLOG.md)

| Faz | Durum |
|-----|-------|
| Faz 1: Firebase + Auth + Temel CRUD | ✅ Tamamlandı |
| Faz 2: Tüm Modüller (M1–M8) | ✅ Tamamlandı |
| Faz 3: Multi-tenant, PDF/DOCX, CI/CD, Testler | ✅ Tamamlandı |
| Faz 4: Güvenlik hijyeni, kalite kapıları, performans | ✅ Tamamlandı |

## 🔐 Erişim

- Anonim/misafir girişi **yoktur**.
- Sadece yetkilendirilmiş e-posta/şifre hesapları ile giriş yapılabilir.
- Rol tabanlı erişim: `super_admin`, `admin`, `birim_yoneticisi`, `kullanici`

## 📖 Dokümantasyon

- [SKILL.md](SKILL.md) — Ajan yetenek dosyası (mimari kurallar, formüller, şablonlar)
- [implementation_plan.md](implementation_plan.md) — Tam kapsamlı uygulama planı
- [BACKLOG.md](BACKLOG.md) — Canlı geliştirme takip listesi
- [SECURITY.md](SECURITY.md) — Güvenlik politikası ve kimlik bilgisi yönetimi
- [MODULE_ACCEPTANCE.md](MODULE_ACCEPTANCE.md) — Modül bazlı done checklist
- [OPERATIONS.md](OPERATIONS.md) — Loglama, hata izleme ve rollback prosedürü
- [RELEASE.md](RELEASE.md) — Web/mobil paketleme ve dağıtım adımları
