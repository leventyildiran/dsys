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
| `GEMINI_API_KEY` | OCR özelliği için runtime `--dart-define` veya CI secret |

### Not

- `firebase_options.dart` ve `android/app/google-services.json` içindeki Firebase proje tanımlayıcıları gizli anahtar değildir; istemci uygulaması için beklenen public konfigürasyondur.
- Credential temizliği kapsamında repoda hardcoded özel anahtar veya service account dosyası tutulmaz.

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

- [x] `firestore.rules` production-grade mı? (test modu kapalı)
- [x] Repoda hardcoded credential taraması tanımlı mı? (`grep -RInE "password|secret|api[_-]?key|token|private_key" . --exclude-dir=.git`)
- [x] `.gitignore` güncel mi? (`.env`, service account dosyaları dahil)
- [x] Firebase Auth'da sadece yetkili hesaplar mı var?
- [x] CI secrets güncel ve aktif mi?
- [x] Dependency audit adımı release sürecinde tanımlı mı? (`flutter pub outdated`)

## Geçmişte Sızıntı Şüphesi İçin Temizleme Adımı

Eğer eski commit'lerde credential sızıntısı tespit edilirse:

1. İlgili secret derhal iptal edilir / rotate edilir.
2. `git filter-repo` veya BFG ile geçmiş temizlenir.
3. Temiz branch zorunlu inceleme sonrası yeniden yayınlanır.
4. GitHub secrets ve çalışma ortamı anahtarları yenilenir.
