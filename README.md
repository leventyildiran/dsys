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
| Modül 1: Danışmanlık Taksit Akışı | 🔄 Devam Ediyor |
| Modül 2–8: Bütçe, Ek Ödeme, Diş Hekimliği, Gündem, Raporlama, EBYS, Fatura | 📌 Sırada |

## 🔐 Erişim

- Anonim/misafir girişi **yoktur**.
- Sadece yetkilendirilmiş e-posta/şifre hesapları ile giriş yapılabilir.
- Rol tabanlı erişim: `super_admin`, `admin`, `birim_yoneticisi`, `kullanici`

## 📖 Dokümantasyon

- [SKILL.md](SKILL.md) — Ajan yetenek dosyası (mimari kurallar, formüller, şablonlar)
- [implementation_plan.md](implementation_plan.md) — Tam kapsamlı uygulama planı
- [BACKLOG.md](BACKLOG.md) — Canlı geliştirme takip listesi
