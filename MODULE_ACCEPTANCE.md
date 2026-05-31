# DSYS Modül Kabul Kriterleri

Bu kontrol listesi bir modülün tamamlandı sayılması için minimum kabul kapısıdır.

## Ortak Done Tanımı

- [ ] Route veya dashboard erişimi eklendi.
- [ ] Provider katmanı yükleme, başarı ve hata durumlarını yönetiyor.
- [ ] Service katmanı CRUD veya işlem mantığını tek sorumlulukla kapsıyor.
- [ ] Firestore yazmaları `universiteler/{universiteId}` altında çalışıyor.
- [ ] Liste ekranı 20 kayıtlık sayfalama ile ilerliyor.
- [ ] Form veya işlem akışı boş veri / hatalı giriş durumlarını ele alıyor.
- [ ] Gerekli doküman üretimi / dışa aktarma akışı bağlandı.
- [ ] İlgili testler eklendi veya güncellendi.
- [ ] Güvenlik açısından hardcoded credential yok.

## Modül Bazlı Kontroller

### Dashboard ve Kimlik Doğrulama
- [ ] Login yalnızca e-posta/şifre ile çalışıyor.
- [ ] Auth-aware redirect splash/login/dashboard akışını koruyor.
- [ ] Rol verisi `users` koleksiyonundan çekiliyor.

### Danışmanlık ve Taksit
- [ ] Hesaplama motoru ile tutarlar doğrulanıyor.
- [ ] Taksit onayında dağıtım kayıtları üretiliyor.
- [ ] Karar belgesi üretimi erişilebilir.

### Bütçe Aktarımları
- [ ] Aktarım satırları ve toplam artırma/eksiltme tutarları kaydediliyor.
- [ ] Karar bilgileri eksiksiz tutuluyor.

### Ek Ödeme ve Diş Hekimliği
- [ ] Katsayı ve dağıtım tutarları tekrar üretilebilir.
- [ ] Durum geçişleri provider üzerinden güncelleniyor.

### Gündem
- [ ] Toplantı listesi ve detay akışı çalışıyor.
- [ ] Sürükle-bırak ile sıra güncellemesi kalıcı.
- [ ] Belge çıktısı üretilebiliyor.

### Raporlama
- [ ] Arama/filtreleme sonuçları boş durumları ele alıyor.
- [ ] Grafik veya özet kartları servis verisiyle besleniyor.

### Evrak Arşivi
- [ ] Evrak listesi arama ve tür filtreleriyle çalışıyor.
- [ ] Gemini OCR ile web üzerinden dosya seçip form doldurma yapılabiliyor.
- [ ] Storage yükleme/indirme akışları güvenli biçimde yönetiliyor.

### Fatura
- [ ] Script-first metin ayrıştırma çalışıyor.
- [ ] Kuyruk ve tüm kayıtlar sayfalı görüntüleniyor.
- [ ] PDF önizleme ve basıldı işaretleme akışı çalışıyor.

### Bütçe Takibi
- [ ] Birim limitleri ve harcama oranları görüntüleniyor.
- [ ] %10 yasal sınır uyarısı YK kararına yönlendiriyor.
