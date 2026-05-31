# 🔐 DSYS Güvenlik Politikası

## Kimlik Bilgisi Yönetimi

### ❌ Asla Yapılmaması Gerekenler

- E-posta adresleri, şifreler veya API anahtarlarını **kaynak koda veya dokümanlara yazmayın**.
- Firebase Service Account JSON dosyalarını repoya **commit etmeyin**.
- `.env` dosyalarını repoya **eklemeyin**.

### ✅ Doğru Yaklaşımlar

| Tür | Saklama Yeri |
|-----|-------------|
| Firebase Auth kullanıcı bilgileri | Firebase Console (web arayüzü) |
| Service Account anahtarları | GitHub Secrets (`FIREBASE_SERVICE_ACCOUNT`) |
| Ortam değişkenleri | `.env` dosyası (gitignore'da) veya CI secrets |
| API anahtarları | Firebase Console / GCP Secret Manager |

### Mevcut CI Secrets

| Secret Adı | Açıklama |
|-----------|----------|
| `FIREBASE_SERVICE_ACCOUNT` | Firebase Hosting deploy için service account JSON |
| `GITHUB_TOKEN` | Otomatik (GitHub tarafından sağlanır) |

---

## Güvenlik Açığı Bildirimi

Bir güvenlik açığı tespit ederseniz:

1. **Herkese açık issue açmayın.**
2. Doğrudan proje yöneticisine özel mesaj gönderin.
3. Açığın detayını, etkisini ve mümkünse çözüm önerisini belirtin.

---

## Firestore Güvenlik Kuralları

- Production kuralları `firestore.rules` dosyasında tanımlıdır.
- Her koleksiyon auth gerektiren `request.auth != null` kontrolü içerir.
- Rol bazlı erişim `users/{userId}` dokümanındaki `role` alanına göre yapılır.
- **Test modunda** (`allow read, write: if true`) kurallar **asla** production'da kullanılmamalıdır.

---

## Güvenlik Kontrol Listesi (Her Release Öncesi)

- [ ] `firestore.rules` production-grade mı? (test modu kapalı)
- [ ] Repoda hardcoded credential var mı? (`grep -r "password\|secret\|apiKey"`)
- [ ] `.gitignore` güncel mi? (`.env`, service account dosyaları dahil)
- [ ] Firebase Auth'da sadece yetkili hesaplar mı var?
- [ ] CI secrets güncel ve aktif mi?
- [ ] Dependency audit yapıldı mı? (`flutter pub outdated`)
