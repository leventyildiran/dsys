import 'package:flutter/foundation.dart';

import '../core/hesaplama_motoru.dart';
import '../models/dagitim_model.dart';
import '../models/danismanlik_model.dart';
import '../models/gorevli_personel_model.dart';
import '../models/sistem_ayarlari_model.dart';
import '../models/taksit_model.dart';
import 'dagitim_service.dart';
import 'data_service.dart';
import 'gorevli_personel_service.dart';
import 'personel_hakedis_service.dart';
import 'taksit_service.dart';
import 'yk_karar_service.dart';
import '../core/karar_metni_servisi.dart';
import '../models/yk_karar_model.dart';

/// Taksit onay → dağıtım hesaplama → EYDMA tavan kontrolü → Firestore yazma
/// pipeline'ını orkestre eden servis.
///
/// M1-1, M1-2, M1-4 görevlerini birleştirir.
class TaksitOnayServisi {
  TaksitOnayServisi({
    TaksitService? taksitService,
    DagitimService? dagitimService,
    GorevliPersonelService? gorevliPersonelService,
    PersonelHakedisService? personelHakedisService,
    DanismanlikService? danismanlikService,
    SistemAyarlariService? sistemAyarlariService,
    YkKararService? ykKararService,
  })  : _taksitService = taksitService ?? TaksitService(),
        _dagitimService = dagitimService ?? DagitimService(),
        _gorevliPersonelService =
            gorevliPersonelService ?? GorevliPersonelService(),
        _personelHakedisService =
            personelHakedisService ?? PersonelHakedisService(),
        _danismanlikService = danismanlikService ?? DanismanlikService(),
        _sistemAyarlariService =
            sistemAyarlariService ?? SistemAyarlariService(),
        _ykKararService = ykKararService ?? YkKararService();

  final TaksitService _taksitService;
  final DagitimService _dagitimService;
  final GorevliPersonelService _gorevliPersonelService;
  final PersonelHakedisService _personelHakedisService;
  final DanismanlikService _danismanlikService;
  final SistemAyarlariService _sistemAyarlariService;
  final YkKararService _ykKararService;

  // ─────────────────────────────────────────────────────────────
  // 1. DURUM GEÇİŞİ
  // ─────────────────────────────────────────────────────────────

  /// Taksit durumunu bir sonraki aşamaya geçirir.
  ///
  /// Geçiş kurallarını kontrol eder ve uygunsuzluk varsa hata fırlatır.
  /// `onaylandi` durumuna geçişte otomatik dağıtım hesaplamasını tetikler.
  Future<DagitimSonuc?> durumGecisi({
    required String danismanlikId,
    required String taksitId,
    required TaksitDurum yeniDurum,
    required TaksitDurum mevcutDurum,
    String? yilAy,
  }) async {
    // Geçiş uygunluğunu kontrol et
    if (!TaksitService.gecisUygunMu(mevcutDurum, yeniDurum)) {
      throw TaksitOnayHatasi(
        '${mevcutDurum.displayName} → ${yeniDurum.displayName} geçişi yapılamaz.',
      );
    }

    // Durumu güncelle
    await _taksitService.durumGecisi(danismanlikId, taksitId, yeniDurum);

    // Onaylandı durumuna geçildiğinde otomatik dağıtım hesapla
    if (yeniDurum == TaksitDurum.onaylandi) {
      return await dagitimHesaplaVeKaydet(
        danismanlikId: danismanlikId,
        taksitId: taksitId,
        yilAy: yilAy,
      );
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // 2. OTOMATİK DAĞITIM HESAPLAMA + FIRESTORE YAZMA
  // ─────────────────────────────────────────────────────────────

  /// Taksit onaylandığında çalıştırılır.
  ///
  /// 1. Danışmanlık bilgilerini çeker (tür, kesinti oranları)
  /// 2. Görevli personel listesini çeker
  /// 3. Kesinti hesaplaması yapar
  /// 4. Katsayı simülasyonu yapar
  /// 5. EYDMA tavan kontrolü uygular
  /// 6. Dağıtım sonuçlarını Firestore'a yazar
  /// 7. PersonelHakedis alt-koleksiyonunu günceller
  Future<DagitimSonuc> dagitimHesaplaVeKaydet({
    required String danismanlikId,
    required String taksitId,
    String? yilAy,
  }) async {
    try {
      // 1. Danışmanlık bilgileri
      final danismanlik = await _danismanlikService.getById(danismanlikId);
      if (danismanlik == null) {
        throw TaksitOnayHatasi('Danışmanlık kaydı bulunamadı.');
      }

      // 2. Taksit bilgileri
      final taksit = await _taksitService.getById(danismanlikId, taksitId);
      if (taksit == null) {
        throw TaksitOnayHatasi('Taksit kaydı bulunamadı.');
      }

      // 3. Görevli personel
      final gorevliler =
          await _gorevliPersonelService.getAll(danismanlikId);
      if (gorevliler.isEmpty) {
        throw TaksitOnayHatasi(
          'Danışmanlığa atanmış görevli personel bulunamadı.',
        );
      }

      // 4. Sistem ayarları (EYDMA kontrolü için)
      final ayarlar = await _sistemAyarlariService.get();
      if (ayarlar == null) {
        throw TaksitOnayHatasi('Sistem ayarları bulunamadı.');
      }

      // 5. Kesinti hesaplaması
      final KesintiBilgisi kesinti;
      if (danismanlik.danismanlikTuru == DanismanlikTuru.standart) {
        kesinti = HesaplamaMotoru.standartKesintiler(
          brutTutar: taksit.brutTutar,
          kdvOrani: danismanlik.kdvOrani,
          hazinePayiOrani: danismanlik.hazinePayiOrani,
          bapPayiOrani: danismanlik.bapPayiOrani,
          aracGerecPayiOrani: danismanlik.aracGerecPayiOrani,
        );
      } else {
        kesinti = HesaplamaMotoru.sanayiIsbirligiKesintiler(
          brutTutar: taksit.brutTutar,
          kdvOrani: danismanlik.kdvOrani,
        );
      }

      // 6. Personel puan modelleri oluştur
      final personelPuanlar = gorevliler
          .map((g) => PersonelPuanModel(
                personelId: g.personelId,
                faaliyetPuani: (g.payOrani / 100.0) * 100, // Pay oranı bazlı
                unvanKatsayisi: g.unvanKatsayisi,
              ))
          .toList();

      double toplamPuan = 0;
      for (final p in personelPuanlar) {
        toplamPuan += p.bireyselPuan;
      }

      if (toplamPuan <= 0) {
        throw TaksitOnayHatasi(
          'Toplam puan sıfır. Personel faaliyet puanları kontrol edilmeli.',
        );
      }

      // 7. Katsayı simülasyonu
      final katsayi = HesaplamaMotoru.katsayiSimulasyonu(
        kesinti.dagitilabilirTutar,
        toplamPuan,
        personelPuanlar,
      );

      // 8. Artık bakiye
      final artikBakiye = HesaplamaMotoru.artikBakiyeHesapla(
        kesinti.dagitilabilirTutar,
        katsayi,
        personelPuanlar,
      );

      // 9. Dönem anahtarı (yıl-ay)
      final donem = yilAy ?? _donemHesapla(taksit.ayNo, danismanlik);

      // 10. EYDMA tavan kontrolü + dağıtım modelleri
      final dagitimlar = <DagitimModel>[];
      final eydma = ayarlar.hesaplananEydma;

      for (final gorevli in gorevliler) {
        final bireyselPuan = (gorevli.payOrani / 100.0) *
            100 *
            gorevli.unvanKatsayisi;
        final brutHakedis =
            double.parse((bireyselPuan * katsayi).toStringAsFixed(2));

        // EYDMA tavan kontrolü (M1-4: canlı veri bağlantısı)
        final toplamMevcutGelir = await _personelHakedisService
            .toplamAylikGelir(gorevli.personelId, donem);

        // Unvan tavanı: EYDMA × 2 (standart çarpan)
        final unvanTavani =
            HesaplamaMotoru.unvanTavaniHesapla(eydma, 200);

        final tavanSonuc = HesaplamaMotoru.tavanKontrol(
          unvanTavani: unvanTavani,
          toplamAylikMevcutGelir: toplamMevcutGelir,
          yeniHesaplananHakedis: brutHakedis,
        );

        final tavanAsildi = tavanSonuc.fazlalikHavuzTutari > 0;

        dagitimlar.add(DagitimModel(
          personelId: gorevli.personelId,
          adSoyad: gorevli.adSoyad,
          unvan: gorevli.unvan,
          unvanKatsayisi: gorevli.unvanKatsayisi,
          toplamPuan: toplamPuan,
          bireyselPuan: bireyselPuan,
          brutHakedis: brutHakedis,
          tavanKontrol: tavanAsildi,
          odenebilirHakedis: tavanSonuc.odenebilirHakedis,
          fazlalikHavuzTutari:
              tavanAsildi ? tavanSonuc.fazlalikHavuzTutari : null,
        ));
      }

      // 11. Firestore'a toplu kaydet
      await _dagitimService.topluKaydet(danismanlikId, taksitId, dagitimlar);

      // 12. Taksit belgesini hesaplama sonuçlarıyla güncelle
      await _taksitService.update(danismanlikId, taksitId, {
        'hazinePayi': kesinti.hazinePayi,
        'bapPayi': kesinti.bapPayi,
        'aracGerecPayi': kesinti.aracGerecPayi,
        'dagitilabilirTutar': kesinti.dagitilabilirTutar,
        'toplamPuan': toplamPuan,
        'ekOdemeKatsayisi': katsayi,
      });

      // 13. PersonelHakedis güncelle (tavan takibi)
      for (final dagitim in dagitimlar) {
        final odenecek = dagitim.odenebilirHakedis ?? dagitim.brutHakedis;
        await _personelHakedisService.donerSermayeEkle(
          dagitim.personelId,
          donem,
          odenecek,
        );
      }

      // 14. Otomatik YK Taslak Kararı Oluştur
      try {
        final isStandart = danismanlik.danismanlikTuru == DanismanlikTuru.standart;
        final ilkGorevli = gorevliler.first;
        
        final hamKararVerileri = {
          'BIRIM_AD': danismanlik.birimId,
          'BIRIM_EVRAK_TARIHI': taksit.birimEvrakTarihi ?? '',
          'BIRIM_EVRAK_SAYISI': taksit.birimEvrakSayisi ?? '',
          'BIRIM_KURUL_TARIHI': taksit.birimKurulTarihi ?? '',
          'BIRIM_TOPLANTI_SAYI': taksit.birimToplantiSayisi ?? '',
          'BIRIM_KARAR_NO': taksit.birimKararNo ?? '',
          'YK_KARAR_TARIHI': danismanlik.ykKararTarihi ?? '',
          'YK_KARAR_NO': danismanlik.ykKararNo ?? '',
          'FIRMA_UNVAN': danismanlik.firmaId,
          'ISIN_KONUSU': danismanlik.konusu,
          'DANISMANLIK_SURESI': danismanlik.suresi,
          'HOCA_UNVAN': ilkGorevli.unvan,
          'HOCA_AD_SOYAD': ilkGorevli.adSoyad,
          'KATSAYI': katsayi,
        };

        final formatliKararVerileri = KararMetniServisi.bicimlendir(hamKararVerileri);
        final kararMetni = KararMetniServisi.metinUret(
          isStandart: isStandart,
          veriler: formatliKararVerileri,
        );

        final ykKarar = YkKararModel(
          id: '',
          toplantiId: '',
          toplantiNo: '',
          kararNo: '',
          kararTarihi: '',
          birimId: danismanlik.birimId,
          birimAd: danismanlik.birimId,
          tur: YkKararTuru.danismanlik,
          baslik: '${ilkGorevli.unvan} ${ilkGorevli.adSoyad} Danışmanlık Taksit Ödemesi (Ay ${taksit.ayNo})',
          kararMetni: kararMetni,
          iliskiliKayitId: taksitId,
          olusturmaTarihi: DateTime.now(),
          durum: YkKararDurum.taslak,
        );
        
        await _ykKararService.create(ykKarar);
      } catch (e) {
        debugPrint('[TaksitOnayServisi.dagitimHesaplaVeKaydet] YK Kararı oluşturulurken hata: $e');
      }

      return DagitimSonuc(
        kesinti: kesinti,
        katsayi: katsayi,
        artikBakiye: artikBakiye,
        dagitimlar: dagitimlar,
        donem: donem,
      );
    } catch (e) {
      debugPrint('[TaksitOnayServisi.dagitimHesaplaVeKaydet] Hata: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. TOPLU ONAY (Birden fazla taksiti tek seferde onayla)
  // ─────────────────────────────────────────────────────────────

  /// Birden fazla taksiti toplu olarak onaylar.
  Future<List<DagitimSonuc>> topluOnay({
    required String danismanlikId,
    required List<String> taksitIdleri,
    required TaksitDurum yeniDurum,
    required TaksitDurum mevcutDurum,
  }) async {
    final sonuclar = <DagitimSonuc>[];

    for (final taksitId in taksitIdleri) {
      final sonuc = await durumGecisi(
        danismanlikId: danismanlikId,
        taksitId: taksitId,
        yeniDurum: yeniDurum,
        mevcutDurum: mevcutDurum,
      );
      if (sonuc != null) {
        sonuclar.add(sonuc);
      }
    }

    return sonuclar;
  }

  // ─────────────────────────────────────────────────────────────
  // YARDIMCI
  // ─────────────────────────────────────────────────────────────

  /// Taksit ayNo'sundan dönem anahtarı hesaplar (YYYY-MM).
  String _donemHesapla(int ayNo, DanismanlikModel danismanlik) {
    if (danismanlik.baslangicTarihi != null) {
      final baslangic = danismanlik.baslangicTarihi!;
      final tarih = DateTime(baslangic.year, baslangic.month + (ayNo - 1));
      final ay = tarih.month.toString().padLeft(2, '0');
      return '${tarih.year}-$ay';
    }
    // Fallback: mevcut tarih bazlı
    final now = DateTime.now();
    final ay = now.month.toString().padLeft(2, '0');
    return '${now.year}-$ay';
  }
}

/// Dağıtım hesaplama sonucu.
class DagitimSonuc {
  const DagitimSonuc({
    required this.kesinti,
    required this.katsayi,
    required this.artikBakiye,
    required this.dagitimlar,
    required this.donem,
  });

  final KesintiBilgisi kesinti;
  final double katsayi;
  final double artikBakiye;
  final List<DagitimModel> dagitimlar;
  final String donem;
}

/// Taksit onay sürecindeki hatalar.
class TaksitOnayHatasi implements Exception {
  const TaksitOnayHatasi(this.mesaj);
  final String mesaj;

  @override
  String toString() => 'TaksitOnayHatasi: $mesaj';
}
