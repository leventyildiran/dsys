# 📋 DSYS Geliştirme Backlog'u

> Son güncelleme: 31.05.2026  
> Yöntem: Kervan yolda dizilir — modül modül, ihtiyaca göre öncelik güncellenir.

---

## ✅ Yapıldı (Tamamlanan)

| # | Öğe | Tarih |
|---|-----|-------|
| 1 | Firebase altyapısı (Core + Auth + Firestore) | Faz 1 |
| 2 | GoRouter ile auth-aware routing (splash → login → dashboard) | Faz 1 |
| 3 | Material 3 tema (Light/Dark, Google Fonts) | Faz 1 |
| 4 | AuthProvider — e-posta/şifre giriş, Türkçe hata mesajları | Faz 1 |
| 5 | UserProvider & UserModel — rol bazlı erişim | Faz 1 |
| 6 | Dashboard ekranı — NavigationRail (web) / BottomNav (mobil) | Faz 1 |
| 7 | Firestore servis katmanı (Generic CRUD + multi-tenant) | Faz 1 |
| 8 | Veri modelleri: Birim, Personel, Firma, Danışmanlık, Taksit, Dağıtım, Faaliyet, SistemAyarları, User, GorevliPersonel, AylikHakedis | Faz 1 |
| 9 | Hesaplama motoru (Standart kesinti, 58/k, katsayı simülasyonu, EYDMA tavan) | Faz 1 |
| 10 | Karar metni servisi (Şablon A & B, placeholder doğrulama) | Faz 1 |
| 11 | Türkçe format yardımcıları (para, tarih, katsayı) | Faz 1 |
| 12 | DanışmanlıkProvider — canlı önizleme hesaplama + kaydetme | Faz 1 |
| 13 | CRUD ekranları: Danışmanlık Liste/Form, Personel, Firma, Birim, Kullanıcı, Sistem Ayarları | Faz 1 |
| 14 | DashboardProvider — hızlı istatistik kartları | Faz 1 |
| 15 | Taksit servisi & Dağıtım servisi (alt-koleksiyon CRUD) | Faz 1 |
| 16 | Görevli personel servisi & PersonelHakedis servisi | Faz 1 |
| 17 | Web deploy (Firebase Hosting: dsys-44b8e.web.app) | Faz 1 |
| 18 | Taksit onay akışı → otomatik dağıtım hesaplama → Firestore'a yazma (M1) | Faz 2 |
| 19 | Word/DOCX belge üretimi (karar metni + faaliyet cetveli tablosu) (M1) | Faz 2 |
| 20 | EYDMA tavan kontrolünün canlı veriye bağlanması (M1) | Faz 2 |
| 21 | Bütçe Aktarımları Modülü (M2) — model, servis, provider, ekran | Faz 2 |
| 22 | Dönemsel Ek Ödeme Dağıtımı (M3) — model, servis, provider, ekran | Faz 2 |
| 23 | Diş Hekimliği Katkı Payı Dağıtım Modülü (M4) — model, servis, provider, ekran | Faz 2 |
| 24 | Toplantı Gündem Derleyici (M5) — model, servis, provider, ekran, sürükle-bırak | Faz 2 |
| 25 | Detaylı Arama, Raporlama ve Arşivleme (M6) — servis, provider, ekran (3 tab) | Faz 2 |
| 26 | Dahili Evrak Arşivi (M7) — model, servis, provider, ekran, arama/filtreleme | Faz 2 |
| 27 | Otomatik Fatura Basım / PDF Önizleme (M8) — model, servis, provider, ekran, metin ayrıştırma | Faz 2 |
| 28 | Router güncellemesi — tüm modül rotaları eklendi | Faz 2 |
| 29 | main.dart — tüm modül provider'ları entegre edildi | Faz 2 |
| 30 | Dashboard navigasyon — tüm modüller menüye eklendi | Faz 2 |
| 31 | Dashboard navigasyon tutarsızlığı giderildi — tüm modüller embed | Faz 3 |
| 32 | Gerçek .docx ZIP arşivi üretimi (archive paketi) | Faz 3 |
| 33 | Dinamik multi-tenant (universiteId kullanıcı profilinden) | Faz 3 |
| 34 | Gerçek PDF fatura üretimi (pdf + printing paketi) | Faz 3 |
| 35 | Firebase Security Rules — production-grade kurallar | Faz 3 |
| 36 | Unit testleri (HesaplamaMotoru, TurkceFormat, KararMetni, UserModel) | Faz 3 |
| 37 | CI/CD pipeline (GitHub Actions → analyze, test, build, deploy) | Faz 3 |
| 38 | Excel import/export servisi (personel listesi yükleme/indirme) | Faz 3 |
| 39 | Güvenlik hijyeni — credential politikası, tarama rutini ve remediation adımları | Faz 4 |
| 40 | Test kapsamı güçlendirme — provider/service testleri ve coverage hedefi | Faz 4 |
| 41 | CI coverage eşiği — %60 altı için fail kapısı | Faz 4 |
| 42 | Firestore listeleme pagination — modül listelerinde 20 kayıt/sayfa | Faz 4 |
| 43 | Operasyon paketi — loglama, hata izleme ve rollback prosedürü | Faz 4 |
| 44 | Modül kabul kriterleri — ortak done checklist'i | Faz 4 |
| 45 | Mobil paketleme ve dağıtım workflow/artifact desteği | Faz 4 |
| 46 | Gemini OCR entegrasyonu — evrak formunu dosyadan doldurma | Faz 4 |

---

## 🔄 Devam Eden

Şu anda aktif geliştirme maddesi yok.

---

## 📌 Sıradaki (Öncelik Sırası)

Yeni ihtiyaçlar keşfedildikçe bu bölüm tekrar doldurulacaktır.

---

## ⏸️ Beklemede (İhtiyaç Çıktıkça)

| # | Öğe | Not |
|---|-----|-----|
| 1 | ~~Firebase Security Rules — production-grade kurallar~~ | ✅ Tamamlandı (firestore.rules) |
| 2 | ~~Birim testleri (unit + widget)~~ | ✅ Tamamlandı (test/ dizini) |
| 3 | ~~CI/CD pipeline (GitHub Actions → Firebase deploy)~~ | ✅ Tamamlandı (.github/workflows/ci.yml) |
| 4 | ~~Çoklu üniversite desteği (multi-tenant dinamik)~~ | ✅ Tamamlandı (FirestoreService.activeUniversiteId) |
| 5 | ~~Gerçek .docx ZIP arşivi üretimi (archive paketi entegrasyonu)~~ | ✅ Tamamlandı (archive paketi ile) |
| 6 | ~~Excel import/export (M4 personel listesi yükleme)~~ | ✅ Tamamlandı (excel paketi ile) |

---

## 🗓️ Güncelleme Politikası

- Bu backlog **ayda en az 1 kez** veya her modül tamamlandığında güncellenir.
- Yeni ihtiyaçlar keşfedildikçe "Sıradaki" veya "Beklemede" listesine eklenir.
- Öncelikler iş değeri, aciliyet ve bağımlılıklara göre yeniden sıralanır.
