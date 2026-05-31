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

---

## 🔄 Devam Eden

| # | Öğe | Durum |
|---|-----|-------|
| 1 | Modül 1 iyileştirmeler: Danışmanlık taksit işlem akışı (onay → dağıtım → karar belgesi üretimi) | Geliştiriliyor |

---

## 📌 Sıradaki (Öncelik Sırası)

| # | Öğe | Modül | Öncelik |
|---|-----|-------|---------|
| 1 | Taksit onay akışı → otomatik dağıtım hesaplama → Firestore'a yazma | M1 | 🔴 Yüksek |
| 2 | Word/DOCX belge üretimi (karar metni + faaliyet cetveli tablosu) | M1 | 🔴 Yüksek |
| 3 | EYDMA tavan kontrolünün canlı veriye bağlanması | M1 | 🟡 Orta |
| 4 | Bütçe Aktarımları Modülü (Modül 2) | M2 | 🟡 Orta |
| 5 | Dönemsel Ek Ödeme Dağıtımı (Modül 3) | M3 | 🟡 Orta |
| 6 | Diş Hekimliği Katkı Payı Dağıtım Modülü (Modül 4) | M4 | 🟡 Orta |
| 7 | Toplantı Gündem Derleyici (Modül 5) | M5 | 🟢 Düşük |
| 8 | Detaylı Arama, Raporlama ve Arşivleme (Modül 6) | M6 | 🟢 Düşük |
| 9 | Dahili Evrak Arşivi / EBYS / OCR (Modül 7) | M7 | 🟢 Düşük |
| 10 | Otomatik Fatura Basım / PDF Önizleme (Modül 8) | M8 | 🟢 Düşük |

---

## ⏸️ Beklemede (İhtiyaç Çıktıkça)

| # | Öğe | Not |
|---|-----|-----|
| 1 | Firebase Security Rules — production-grade kurallar | Deploy öncesi |
| 2 | Birim testleri (unit + widget) | Çekirdek mantık stabilize olunca |
| 3 | CI/CD pipeline (GitHub Actions → Firebase deploy) | Takım büyüyünce |
| 4 | Çoklu üniversite desteği (multi-tenant dinamik) | İlk canlıdan sonra değerlendirilecek |
| 5 | Mobil (Android/iOS) paketleme ve dağıtım | Web stabil olunca |
| 6 | Performans optimizasyonu (pagination, lazy loading) | Veri hacmi artınca |

---

## 🗓️ Güncelleme Politikası

- Bu backlog **ayda en az 1 kez** veya her modül tamamlandığında güncellenir.
- Yeni ihtiyaçlar keşfedildikçe "Sıradaki" veya "Beklemede" listesine eklenir.
- Öncelikler iş değeri, aciliyet ve bağımlılıklara göre yeniden sıralanır.
