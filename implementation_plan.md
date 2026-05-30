# 🏛️ Döner Sermaye Yönetim Sistemi (DSYS)
## Uşak Üniversitesi — Tam Kapsamlı Uygulama Planı (Güncellenmiş)

---

## 1. Proje Özeti ve Amaç

Uşak Üniversitesi Döner Sermaye İşletmesi'nin **Yürütme Kurulu kararlarını** yarı-otomatik olarak yönetecek, **evrak üzerinden yapılan tüm işlemleri dijitalleştirecek** bir Web + Mobil uygulama geliştirmek.

### Temel Felsefe
- **Banka entegrasyonu YOK** — Ödeme takibi tamamen manuel
- **Yarı-otomatik** — Mevcut evrak süreçleri dijitale taşınıyor
- **Hesaplama motoru** — Excel'de yapılan tüm kesinti/dağıtım/katsayı hesapları otomatik
- **Belge üretimi** — Yürütme Kurulu'na sunulacak Word tabloları ve karar metinleri otomatik oluşturulacak
- **Misafir/Anonim giriş YASAK** — Sadece Firebase Authentication

> [!IMPORTANT]
> Bu proje, mevcut G-revde-Y-kselme Flutter uygulamasından **tamamen bağımsız** yeni bir projedir.

---

## 2. Teknoloji Yığını (Tech Stack)

| Katman | Teknoloji | Açıklama |
|--------|-----------|----------|
| **Frontend (Web + Mobil)** | Flutter | Tek kod tabanıyla Web, Android, iOS |
| **Backend** | Firebase | Firestore, Cloud Functions, Storage |
| **Kimlik Doğrulama** | Firebase Authentication | E-posta/Şifre bazlı giriş |
| **Veritabanı** | Cloud Firestore | NoSQL, gerçek zamanlı |
| **Dosya Depolama** | Firebase Storage | Evrak/belge yükleme |
| **Belge Üretimi** | `docx` paketi (Dart) | Word şablonları |
| **Excel Üretimi** | `syncfusion_flutter_xlsio` veya `excel` paketi | Ödeme listeleri |
| **PDF Üretimi** | `pdf` paketi (Dart) | Raporlar |
| **State Yönetimi** | Provider | Uygulama geneli state |
| **Routing** | GoRouter | Deklaratif navigasyon |
| **Tema** | Material 3 + Google Fonts | Kurumsal tasarım |

---

## 3. Kullanıcı Rolleri ve Yetkilendirme

Sistemde hiyerarşik ve birim bazlı yetkilendirme modeli kullanılır. Kullanıcılar sadece yetkili oldukları birimlerin (`birimId`) verilerine erişebilirler.

| Rol | Sistem Yetki Düzeyi | Açıklama |
|-----|----------------------|----------|
| **Süper Admin** | Global (Tüm Üniversite) | Üniversite ekleme, kullanıcı tanımlama/yetkilendirme, sistem katsayıları güncelleme. |
| **YK Sekreteri (Sen)** | Global (Tüm Üniversite) | Birimlerden gelen talepleri onaylama, YK Kararı ve banka Excel listesi üretme, genel raporları izleme. |
| **Birim Müdürü (Dekan/Merkez Müd.)** | Birim Kısıtlı (`birimId`) | Birim sekreterinin hazırladığı taslakları inceleme, düzeltme ve onaylayarak YK Sekreteri'ne (Merkez) gönderme. |
| **Birim Sekreteri** | Birim Kısıtlı (`birimId`) | Kendi birimine ait personel, danışmanlık ve taksit verilerini girme, "Müdür Onayına Sunma". |
| **Muhasebe** | Global veya Birim Kısıtlı | Onaylanan kararların banka listelerini/bordrolarını indirme ve "Ödendi" olarak işaretleme. |

### 3.1 Kullanıcı Tanımlama ve Yönetim Akışı
1.  **Kullanıcı Ekleme/Davet:** Süper Admin veya YK Sekreteri, "Kullanıcı Yönetimi" panelinden **"Yeni Kullanıcı Davet Et"** butonuna basar.
2.  **Bilgi Girişi:** Davet edilecek kişinin `E-posta`, `Ad Soyad`, `Rol` ve `Birim` (eğer birim kısıtlı bir rol ise) bilgileri girilir.
3.  **Aktivasyon:** Sisteme eklenen kullanıcıya bir davet maili gider. Kullanıcı ilk girişinde kendi şifresini belirleyerek Firebase Auth üzerinde hesabını aktif hale getirir.

---

## 4. Veritabanı Mimarisi (Firestore)

### 4.1 Ana Koleksiyonlar

```
firestore-root/
├── users/                          # Kullanıcı profilleri
│   └── {userId}/
│       ├── displayName
│       ├── email
│       ├── role                    # super_admin, yk_sekreteri, birim_muduru, birim_sekreteri, muhasebe
│       ├── birimId                 # Bağlı olduğu birim (Global rollerde null veya "all")
│       ├── universiteId            # SaaS modeli için bağlı olduğu üniversite
│       └── aktif                   # true/false
│
├── birimler/                       # Üniversite birimleri
│   └── {birimId}/
│       ├── ad                      # "Deri Tekstil ve Seramik Tasarım Uygulama ve Araştırma Merkezi"
│       ├── kisaAd                  # "DTS"
│       ├── tur                     # merkez, fakulte, enstitu, meslek_yuksekokulu
│       ├── mudurAd                 # Merkez müdürü adı
│       └── aktif                   # true/false
│
├── personel/                       # Akademik personel
│   └── {personelId}/
│       ├── tcKimlikNo
│       ├── adSoyad                 # "Öğr. Gör. Dr. Neslihan ÖPÖZ VURAL"
│       ├── unvan                   # "Öğr. Gör. Dr."
│       ├── unvanKatsayisi          # 2.00
│       ├── birimId                 # Bağlı olduğu birim
│       ├── iban
│       ├── aktif                   # true/false
│       └── aylikToplamHakedis/     # Alt koleksiyon: aylık tavan takibi
│           └── {yilAy}/           # "2026-04"
│               ├── donerSermaye
│               ├── ikinciOgretim
│               └── toplam
│
├── firmalar/                       # Hizmet alan firmalar (CRM)
│   └── {firmaId}/
│       ├── unvan                   # "Orhan Şaşmaz Tekstil İnşaat Turizm San. ve Tic. Ltd. Şti."
│       ├── vergiNo
│       ├── vergiDairesi
│       ├── adres
│       ├── telefon
│       ├── yetkiliKisi
│       └── aktif
│
├── faaliyetTanimlari/              # Faaliyet türleri ve puanları
│   └── {faaliyetId}/
│       ├── ad                      # "Tasarım", "Eğitim", "Teknik Uygulama", vb.
│       ├── puan                    # 20, 10, 20, vb.
│       ├── birim                   # "Adet", "Saat"
│       └── aktif
│
├── danismanliklar/                 # ANA MODÜL
│   └── {danismanlikId}/
│       ├── birimId                 # DTS, UBATAM, TUDAM...
│       ├── firmaId
│       ├── danismanlikTuru         # "standart" veya "sanayi_isbirligi_58k"
│       ├── konusu                  # "Tasarım, tasarım danışmanlığı, ürün geliştirme..."
│       ├── toplamTutar             # 48000.00 (KDV Hariç)
│       ├── kdvOrani               # 20 (yüzde)
│       ├── suresi                  # 6 (ay)
│       ├── baslangicTarihi
│       ├── bitisTarihi
│       ├── durum                   # bekliyor, aktif, tamamlandi, iptal
│       │
│       │── # ÇATI KARAR BİLGİLERİ (Yürütme Kurulu İlk Onay)
│       ├── ykKararTarihi           # "25/11/2025"
│       ├── ykKararNo              # "2025/20-94"
│       ├── ykToplantıSayisi       # "20"
│       │
│       │── # KESİNTİ ORANLARI (Sözleşmeye özel - standart tür için geçerli)
│       ├── hazinePayiOrani         # 1 (yüzde)
│       ├── bapPayiOrani            # 5 (yüzde)
│       ├── aracGerecPayiOrani      # 45 (yüzde)
│       ├── dagitilabiilirOran      # 49 (yüzde)
│       │
│       │── # GÖREVLİ PERSONEL
│       ├── gorevliPersonel/        # Alt koleksiyon
│       │   └── {atama}/
│       │       ├── personelId
│       │       ├── payOrani        # %100, %60, %40 vb.
│       │       └── faaliyetler/    # Her ay değişebilir
│       │           └── {faaliyetId}/
│       │               ├── faaliyetAdi
│       │               ├── puan
│       │               ├── birimi
│       │               └── varsayilanMiktar  # Opsiyonel
│       │
│       │── # AYLIK TAKSİTLER
│       └── taksitler/              # Alt koleksiyon
│           └── {taksitId}/         # "ay-1", "ay-2", ...
│               ├── ayNo            # 1, 2, 3...
│               ├── brutTutar       # 8000.00
│               ├── durum           # taslak, mudur_onayinda, merkez_onayinda, yk_gundeminde, onaylandi, odendi, gecikti
│               ├── odemeTarihi     # null veya tarih
│               │
│               │── # DTS'DEN GELEN EVRAK BİLGİLERİ
│               ├── birimEvrakTarihi    # "20.04.2026"
│               ├── birimEvrakSayisi    # "E.345322"
│               ├── birimKurulTarihi    # "14.04.2026"
│               ├── birimToplantiSayisi # "03"
│               ├── birimKararNo        # "2026/12"
│               │
│               │── # OTOMATİK HESAPLAMA SONUÇLARI
│               ├── hazinePayi          # 80.00
│               ├── bapPayi             # 400.00
│               ├── aracGerecPayi       # 3600.00
│               ├── dagitilabiilirTutar # 3920.00
│               │
│               │── # PUAN & KATSAYI HESABI
│               ├── toplamPuan          # 200
│               ├── ekOdemeKatsayisi    # 19.50
│               │
│               │── # KİŞİ BAZLI DAĞITIM
│               └── dagitim/
│                   └── {personelId}/
│                       ├── adSoyad
│                       ├── unvan
│                       ├── unvanKatsayisi
│                       ├── toplamPuan
│                       ├── bireyselPuan      # puan × unvan katsayısı
│                       ├── brutHakedis       # bireyselPuan × ekOdemeKatsayisi
│                       ├── tavanKontrol      # true/false (aşıyor mu?)
│                       └── faaliyetDetay/    # O ayki faaliyet kırılımı
│                           └── {faaliyetId}/
│                               ├── faaliyetAdi
│                               ├── miktar    # 5 (adet)
│                               ├── puan      # 20
│                               └── toplamPuan # 100
│
├── butceAktarimlari/               # Bütçe aktarım kararları
│   └── {aktarimId}/
│       ├── birimId
│       ├── kararTarihi
│       ├── kararNo
│       ├── artirilanBolum
│       ├── artirilanMadde
│       ├── artirilanTutar
│       ├── eksiltilenBolum
│       ├── eksiltilenMadde
│       ├── eksiltilenTutar
│       └── gerekce
│
├── ekOdemeler/                     # Dönemsel ek ödeme dağıtımları
│   └── {ekOdemeId}/
│       ├── birimId
│       ├── donem                   # "Ocak-Şubat-Mart 2025"
│       ├── katsayi                 # 20.25 veya 0.42
│       ├── toplamDagitilanTutar
│       └── personelListesi/
│           └── {personelId}/
│               ├── adSoyad
│               ├── unvan
│               ├── puan
│               ├── unvanKatsayisi
│               └── hakedis
│
├── kurslar/                        # Kurs ücreti belirlemeleri
│   └── {kursId}/
│       ├── birimId
│       ├── kursAdi
│       ├── ucret
│       ├── kararNo
│       └── kararTarihi
│
└── sistemAyarlari/                 # Tek döküman
    └── genel/
        ├── memurMaasKatsayisi       # 1.387871
        ├── eydmaGosterge            # 9500 (1500+8000)
        ├── hesaplananEydma          # 9500 × katsayı
        ├── varsayilanKesintiler/
        │   ├── hazinePayi           # 1
        │   ├── bapPayi              # 5
        │   ├── aracGerecPayi        # 45
        │   └── dagitilabilir        # 49
        ├── unvanKatsayilari/
        │   ├── profesor              # 3.00
        │   ├── docent                # 2.50
        │   ├── drOgrUyesi            # 2.20
```

### 5. İş Mantığı Kuralları ve Belge Üretimi

#### 5.4.1 Dinamik Kesinti ve Matrah Hesaplama
Sistemdeki tüm KDV ve kesinti oranları veri tabanından dinamik olarak çekilir ve asla kod içinde sabitlenmez (hardcoded yapılmaz).

**Kullanılan Dinamik Değişkenler:**
- `kdvOrani`: `%0`, `%10`, `%20` veya gelecekte değişebilecek KDV oranları.
- `hazinePayiOrani`, `bapPayiOrani`, `aracGerecPayiOrani`: Birim veya sözleşme bazlı Firestore'da saklanan yüzdelik kesinti oranları.

**Hesaplama Adımları:**
1. **KDV Dahil Tutardan KDV Hariç Matrahın Bulunması:**
   ```
   kdvHaricMatrah = ROUND( brutTaksitTutarı / (1 + (kdvOrani / 100)), 2 )
   ```
   *Örnek:* `9.600,00 TL (KDV Dahil) / (1 + (20 / 100)) = 8.000,00 TL`

2. **Türe Göre Dinamik Dağıtım ve Kesinti Kuralları:**
   - **A) EĞER `danismanlikTuru == "standart"` ise (Normal Akış):**
     Sırasıyla yasal kesintiler matrahtan düşülür:
     ```
     Hazine Payı      = ROUND( kdvHaricMatrah * (hazinePayiOrani / 100), 2 )
     BAP Payı         = ROUND( kdvHaricMatrah * (bapPayiOrani / 100), 2 )
     Araç Gereç Payı  = ROUND( kdvHaricMatrah * (aracGerecPayiOrani / 100), 2 )
     
     DagitilabilirTutar = kdvHaricMatrah - (Hazine Payı + BAP Payı + Araç Gereç Payı)
     ```
   - **B) EĞER `danismanlikTuru == "sanayi_isbirligi_58k"` ise (Sanayi İşbirliği Akışı):**
     YÖK Kanunu 58(k) gereğince hazine, BAP ve araç-gereç payları **kesilmez**. Doğrudan %85 oranı uygulanır:
     ```
     Hazine Payı      = 0.00
     BAP Payı         = 0.00
     Araç Gereç Payı  = 0.00
     
     DagitilabilirTutar = ROUND( kdvHaricMatrah * 0.85, 2 )
     Birim Kalanı (%15)  = kdvHaricMatrah - DagitilabilirTutar
     ```

#### 5.4.2 Kuruş Yuvarlama Katsayı Simülasyonu
Dağıtılabilir tutar hocaların toplam puanına bölündüğünde kuruş yuvarlamalarından ötürü hocalara ödenecek toplam para, dağıtılabilir bütçeyi (kasadaki parayı) **aşabilir**. Bu taşmayı (overflow) sıfıra indirmek ve tam doğruluğu sağlamak için sistem aşağıdaki simülasyon döngüsünü çalıştıracaktır:

1. **Hassas Katsayı Başlangıç Değeri:**
   ```
   hassasKatsayi = DagitilabilirTutar / ToplamPuan
   Katsayi = floor(hassasKatsayi * 100) / 100  (Virgülden sonra 2 basamak)
   ```
2. **Kuruş Taşma Simülasyonu (Algoritma Döngüsü):**
   ```dart
   double katsayiSimulasyonu(double dagitilabilirTutar, double toplamPuan, List<PersonelPuanModel> personeller) {
     double katsayi = double.parse((dagitilabilirTutar / toplamPuan).toStringAsFixed(2));
     
     while (true) {
       double hakedisToplam = 0.0;
       
       for (var personel in personeller) {
         double bireyselPuan = personel.faaliyetPuani * personel.unvanKatsayisi;
         double hakedis = double.parse((bireyselPuan * katsayi).toStringAsFixed(2));
         hakedisToplam += hakedis;
       }
       
       if (hakedisToplam > dagitilabilirTutar) {
         katsayi = double.parse((katsayi - 0.01).toStringAsFixed(2));
       } else {
         break;
       }
     }
     return katsayi;
   }
   ```
3. **Artık Bakiye (Birim Bütçe Havuzuna Aktarım):**
   Simüle edilen katsayı ile hesaplanan hakedişler dağıtıldıktan sonra kalan artık kuruşlar bir sonraki ay kullanılmak üzere birimin bakiye kasasına yazılır:
   ```
   artikBakiye = DagitilabilirTutar - SUM(ROUND(bireyselPuan * Katsayi, 2))
   ```

#### 5.4.3 Dinamik EYDMA Limit Kontrol Modeli
- **EYDMA Gösterge Limitleri:** `1500` (ek gösterge) ve `8000` (makam/temsil) değerleri ile `memurMaasKatsayisi` sistem ayarlarından çekilir:
  ```
  eydma = (gostergeEk + gostergeMakamTemsil) * memurMaasKatsayisi
  ```
- **Hoca Yasal Tavanı:** `unvanTavani = eydma * (unvanTavanCarpani / 100)`
- **Sistem İçi ve Dış Gelir Entegrasyonlu Kontrol:**
  Hocanın o aya ait diğer döner sermaye gelirleri, ikinci öğretim gelirleri ve sistem içi diğer danışmanlıklarından hak ettiği paralar toplanır:
  ```
  toplamAylikMevcutGelir = disGelirDonerSermaye + disGelirIkinciOgretim + sistemIciDigerHakedisler
  kalanTavanLimiti = max(0.0, unvanTavani - toplamAylikMevcutGelir)
  
  if (yeniHesaplananHakedis > kalanTavanLimiti) {
    odenebilirHakedis = kalanTavanLimiti;
    fazlalikHavuzTutari = yeniHesaplananHakedis - odenebilirHakedis;
  } else {
    odenebilirHakedis = yeniHesaplananHakedis;
    fazlalikHavuzTutari = 0.0;
  }
  ```

---

### 5.5 Otomatik Belge Üretimi ve Şablon Yönetimi

Sistemde üretilecek tüm `.docx` belgeleri, `assets/templates/` dizininde saklanan gerçek şablon dosyaları üzerinden çalışacaktır. Belge üretilirken metinlerin içindeki belirli anahtarlar (placeholder) Firestore verileriyle değiştirilerek yeni dosya oluşturulur.

#### 5.5.1 Değişken Eşleştirme Listesi (Placeholder Mapping)

| Şablon Değişkeni | Firestore Eşleşmesi | Açıklama |
|------------------|----------------------|----------|
| `{BIRIM_AD}` | `birimler/{birimId}/ad` | Birimin tam adı |
| `{BIRIM_EVRAK_TARIHI}` | `taksitler/{taksitId}/birimEvrakTarihi` | Üst yazı evrak tarihi |
| `{BIRIM_EVRAK_SAYISI}` | `taksitler/{taksitId}/birimEvrakSayisi` | Üst yazı evrak sayısı |
| `{BIRIM_KURUL_TARIHI}` | `taksitler/{taksitId}/birimKurulTarihi` | Birim Yönetim Kurulu tarihi |
| `{BIRIM_TOPLANTI_SAYI}`| `taksitler/{taksitId}/birimToplantiSayisi`| Birim kurul toplantı sayısı |
| `{BIRIM_KARAR_NO}` | `taksitler/{taksitId}/birimKararNo` | Birim kurul karar no |
| `{YK_KARAR_TARIHI}` | `danismanliklar/{id}/ykKararTarihi` | Çatı karar tarihi |
| `{YK_KARAR_NO}` | `danismanliklar/{id}/ykKararNo` | Çatı karar numarası |
| `{FIRMA_UNVAN}` | `firmalar/{firmaId}/unvan` | Firma resmi unvanı |
| `{ISIN_KONUSU}` | `danismanliklar/{id}/konusu` | Danışmanlık konusu |
| `{DANISMANLIK_SURESI}` | `danismanliklar/{id}/suresi` | Ay bazında süre |
| `{HOCA_UNVAN}` | `personel/{id}/unvan` | Hoca akademik unvanı |
| `{HOCA_AD_SOYAD}` | `personel/{id}/adSoyad` | Hoca adı soyadı |
| `{KATSAYI}` | `taksitler/{taksitId}/ekOdemeKatsayisi`| Dönem katsayısı |

#### 5.5.2 Dinamik Faaliyet Cetveli Tablosu (Word)
Şablondaki tablo alanı, atanan hocaların sayısına göre dinamik olarak sütun eklenerek oluşturulacaktır. `docx` kütüphanesi yardımıyla tablolar hücre hücre doldurulacak ve boş satırlar kaldırılacaktır.

---

### 5.6 Yürütme Kurulu Karar Metni Şablon Motoru ve Metin Kuralları

Resmi evraklarda en ufak bir biçim, noktalama veya veri hatası olmaması için şablon motoru aşağıdaki katı kurallarla çalışacaktır.

#### 5.6.1 Metin Biçimlendirme Kuralları (Sanitizer & Formatter)
1. **Para Birimi Biçimlendirmesi:** Tüm parasal tutarlar Türkçe para formatına uygun olarak yazılacaktır: Binlik ayırıcı nokta (`.`), Ondalık ayırıcı virgül (`,`). Örnek: `120.000,00 TL`.
2. **Tarih Biçimlendirmesi:** Gün/ay/yıl formatı: `dd.MM.yyyy` (Örn: `20.04.2026`).
3. **Katsayı Biçimlendirmesi:** Katsayılar virgülden sonra 2 basamak olacaktır. Örnek: `19,50` veya `9,75`.
4. **Tırnak İşaretleri:** Karar konuları yazılırken resmi karar metinlerinde kullanılan tipografik tırnaklar (`“` ve `”`) kullanılacaktır.

#### 5.6.2 Kelimesi Kelimesine Karar Şablonları

##### ŞABLON A: Standart Danışmanlık Karar Şablonu (`danismanlikTuru == "standart"`)
```text
Üniversitemiz {BIRIM_AD} Müdürlüğü’nün {BIRIM_EVRAK_TARIHI} tarih ve {BIRIM_EVRAK_SAYISI} sayılı yazısı ile {BIRIM_KURUL_TARIHI} tarih, {BIRIM_TOPLANTI_SAYI} toplantı sayılı ve {BIRIM_KARAR_NO} numaralı kararına istinaden; Döner Sermaye Yürütme Kurulu’nun {YK_KARAR_TARIHI} tarih ve {YK_KARAR_NO} sayılı kararı ile {FIRMA_UNVAN}’nin talep ettiği “{ISIN_KONUSU}” kapsamında {DANISMANLIK_SURESI} ay süreyle Danışmanlık Hizmeti için görevlendirilen {HOCA_UNVAN} {HOCA_AD_SOYAD} tarafından verilen danışmanlık hizmetine istinaden elde edilen gelirden ayrılan katkı payından aşağıdaki gelir getirici faaliyet cetveli doğrultusunda, dönem ek ödeme katsayısının {KATSAYI} şeklinde belirlenmesi ve elde edilen puanlara göre hesaplanacak katkı payı dağıtımının gerçekleştirilmesine;
```

##### ŞABLON B: Sanayi İşbirliği Karar Şablonu (`danismanlikTuru == "sanayi_isbirligi_58k"`)
```text
Üniversitemiz Yönetim Kurulunun {UYK_KARAR_TARIHI} tarih, {UYK_TOPLANTI_SAYI} toplantı sayılı, {UYK_KARAR_NO} numaralı kararıyla 2547 Sayılı Yükseköğretim Kanunun 58. maddesinin (k) fıkrası kapsamında {FIRMA_UNVAN} ye teknik danışmanlık hizmeti vermek üzere görevlendirilen {HOCA_UNVAN} {HOCA_AD_SOYAD} tarafından {HIZMET_BASLANGIC_TARIHI}-{HIZMET_BITIS_TARIHI} ({DANISMANLIK_SURESI} Aylık) tarihleri arasında gerçekleştirilen hizmet için elde edilen {GELIR_TUTARI} TL gelirden ayrılan {KATKI_PAYI_TUTARI} TL katkı payının adı geçen öğretim üyesine tahakkuk ettirilmesine;
```

#### 5.6.3 Karar Altı Dinamik Tablo Ekleme Motoru

##### Tablo 1: Bütçe Aktarım Tablosu (Modül 2 için)
```text
┌────────┬───────────┬────────────────────────────────┬───────────┬───────────┬──────────────────────┐
│ BÖLÜM  │ MADDE     │ Rektörlükçe Kabul Edilen Gider │ Artırılan │ Eksiltilen│ Aktarmanın Gerekçesi │
├────────┼───────────┼────────────────────────────────┼───────────┼───────────┼──────────────────────┤
│ {bolum}│ {madde}   │ {kabulEdilenGider}             │ {artir}   │ {eksilt}  │ {gerekce}            │
└────────┴───────────┴────────────────────────────────┴───────────┴───────────┴──────────────────────┘
```

##### Tablo 2: Diş Hekimliği Katkı Payı Tablosu (Modül 4 için)
```text
┌──────────────────────────────────────────────────────────────┬───────────────────────────────┐
│ Personel Bilgisi                                             │ Dağıtılacak Toplam Tutar      │
├──────────────────────────────────────────────────────────────┼───────────────────────────────┤
│ Gelirin Elde Edilmesinde Katkısı Bulunan Birimde Görevli     │ {akademikIdariTutar}          │
│ Akademik ve İdari Personel                                   │                               │
├──────────────────────────────────────────────────────────────┼───────────────────────────────┤
│ Yönetici Payı                                                │ {yoneticiTutar}               │
├──────────────────────────────────────────────────────────────┼───────────────────────────────┤
│ Mesai Dışı (Ücretli) Tedavi Ödemesi                          │ {mesaiDisiTutar}              │
└──────────────────────────────────────────────────────────────┴───────────────────────────────┘
```

---

## 6. DİĞER MODÜLLER

### 6.1 MODÜL 2: Bütçe Aktarımları Modülü
Birimlerin bütçe kalemleri arasında yaptıkları aktarımların Yürütme Kurulu onay kararlarını yönetir. `2Yürütme Kurulu Kararları.docx` bütçe tablosunu birebir çizer ve karar metnini içeren Word belgesini otomatik üretir.

### 6.2 MODÜL 3: Dönemsel Ek Ödeme Dağıtımı
Birimlerin (UBATAM, TUDAM vb.) havuzunda biriken paraların hocalara unvan katsayısı ve puan bazlı dönemsel dağıtımı (`Hakediş = Bireysel Puan * Dönem Katsayısı`).

### 6.3 MODÜL 4: Diş Hekimliği Katkı Payı Dağıtım Modülü
Merkezin yüksek bütçeli dönemsel ödemelerini yönetir. Hem hızlı brüt tutar girişini hem de hoca bazlı detaylı listenin Excel ile yüklenmesini destekleyen **esnek seçmeli** bir yapıda olacaktır.

### 6.4 MODÜL 5: Toplantı Gündem Derleyici
Toplantı öncesi tüm gündem kararlarını sürükle-bırak yöntemiyle sıraya koyup `Toplantı Gündem Maddeleri.docx` formatında çıktı üreten modüldür.

### 6.5 MODÜL 6: Detaylı Arama, Raporlama ve Arşivleme
Tüm kararların yıl bazlı izole sorgulanması, gelir/dağıtım analizi, birim performansları ve hoca bazlı yıllık gelir arşivlerini barındıran karşılaştırmalı raporları içerir.

### 6.6 MODÜL 7: Dahili Evrak Arşivi ve EBYS Özellik Kopyası (Akıllı Evrak Okuma)
- **OCR + Gemini ile Akıllı Form Doldurucu:** EBYS'den yüklenen üst yazı PDF'lerini otomatik tarayarak hoca, tutar, tarih gibi bilgileri forma yansıtır.
- **Dahili Güvenli Onay Zinciri & Doğrulama QR:** SMS OTP veya şifreli mühür ile onaylanan belgelere doğrulama barkodu ve QR kodu basılarak arşivlenir.

---

## 14. Karara Bağlanan Tasarım Seçimleri
1.  **Artık Bakiye Yönetimi:** Yuvarlamadan kalan artık kuruş tutarları, danışmanlık bütçesinde dağıtılabilir miktar hesaplandıktan sonra birimin genel havuzunda (bakiye kasası) biriktirilecektir.
2.  **Memur Katsayısı Tarihçesi:** Memur katsayısı değiştiğinde geriye dönük hesaplamaların bozulmaması amacıyla geçmiş aylar işlem tarihindeki katsayıyla kilitli/sabit kalacak, asla bozulmayacaktır.
3.  **Diş Hekimliği Modülü:** Hem sadece toplu brüt tutarları girerek hızlı karar metni üretme özelliğini hem de gerektiğinde hoca bazlı detaylı listeyi Excel ile yükleyip işleme seçeneğini içeren esnek bir yapıda kurulacaktır.

---

## 15. Proje Ajan Yetenekleri (SKILL.md)
Yapay zeka ajanının Flutter, Firebase ve projeye özel hesaplama/şablon kurallarını en yüksek standartta, Clean Architecture, Dependency Injection ve Memory Leak koruması ile eksiksiz uygulayabilmesi için `SKILL.md` dosyası oluşturulmuştur.

---

## 16. Faz 1: Firebase Altyapısı ve Kimlik Doğrulama Planı

Bu fazda, `E:\antivaty\dsys` dizinindeki yeni Flutter projesine Firebase bağlantısı eklenecek ve GoRouter ile güvenli giriş akışı (Auth Redirect) kurulacaktır.

### Önerilen Dosya Değişiklikleri:

#### [MODIFY] [pubspec.yaml](file:///e:/antivaty/dsys/pubspec.yaml)
- Firebase bağımlılıkları (`firebase_core`, `firebase_auth`, `cloud_firestore`) eklenecek.
- Yardımcı kütüphaneler (`provider`, `go_router`, `google_fonts`) eklenecek.

#### [NEW] [firebase_options.dart](file:///e:/antivaty/dsys/lib/firebase_options.dart)
- `gorevde-yukselme-app` projesi referans alınarak (Web ve Android için) Firebase konfigürasyon sınıfı oluşturulacak.

#### [NEW] [google-services.json](file:///e:/antivaty/dsys/android/app/google-services.json)
- Android derlemesi için gerekli Firebase yapılandırma dosyası oluşturulacak/kopyalanacak.

#### [NEW] [main.dart](file:///e:/antivaty/dsys/lib/main.dart)
- Firebase `initializeApp` çağrısı eklenecek.
- `MultiProvider` ile `AuthProvider` enjekte edilecek.
- `MaterialApp.router` ile GoRouter entegre edilecek.

#### [NEW] [theme.dart](file:///e:/antivaty/dsys/lib/theme.dart)
- Material 3 renk paleti (`ColorScheme.fromSeed`) ve Google Fonts (Outfit/Roboto) entegrasyonu tanımlanacak.
- Light ve Dark tema verileri oluşturulacak.

#### [NEW] [router.dart](file:///e:/antivaty/dsys/lib/router.dart)
- Rotalar tanımlanacak (`/splash`, `/login`, `/dashboard`).
- Kullanıcının oturum durumuna göre otomatik yönlendirme (redirect) kuralları eklenecek (Giriş yapmamışsa login ekranına, yapmışsa dashboard'a).

#### [NEW] [auth_provider.dart](file:///e:/antivaty/dsys/lib/providers/auth_provider.dart)
- Firebase Authentication durumu (`authStateChanges`) izlenecek.
- E-posta/Şifre ile giriş (`signInWithEmailAndPassword`) ve çıkış (`signOut`) işlevleri yazılacak.
- Asenkron yükleme durumları için `loading` state yönetilecek.

#### [NEW] [splash_screen.dart](file:///e:/antivaty/dsys/lib/screens/splash_screen.dart)
- Uygulama ilk açıldığında veya oturum kontrol edilirken gösterilecek, null hatalarını ve UI kilitlenmelerini önleyen yükleme ekranı.

#### [NEW] [login_screen.dart](file:///e:/antivaty/dsys/lib/screens/login_screen.dart)
- Şık bir Material 3 giriş arayüzü.
- **Kesin Kural:** Misafir girişi (Guest Login) butonu yer almayacak. Sadece geçerli E-posta/Şifre ile giriş yapılabilecek.
