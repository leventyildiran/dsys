import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsys/core/paginated_result.dart';
import 'package:dsys/models/butce_aktarim_model.dart';
import 'package:dsys/models/dis_hekimligi_model.dart';
import 'package:dsys/models/ek_odeme_model.dart';
import 'package:dsys/models/evrak_arsiv_model.dart';
import 'package:dsys/models/evrak_ocr_sonucu.dart';
import 'package:dsys/models/fatura_model.dart';
import 'package:dsys/models/gundem_model.dart';
import 'package:dsys/providers/butce_aktarim_provider.dart';
import 'package:dsys/providers/dis_hekimligi_provider.dart';
import 'package:dsys/providers/ek_odeme_provider.dart';
import 'package:dsys/providers/evrak_arsiv_provider.dart';
import 'package:dsys/providers/fatura_provider.dart';
import 'package:dsys/providers/gundem_provider.dart';
import 'package:dsys/services/butce_aktarim_service.dart';
import 'package:dsys/services/dis_hekimligi_service.dart';
import 'package:dsys/services/ek_odeme_service.dart';
import 'package:dsys/services/evrak_arsiv_service.dart';
import 'package:dsys/services/fatura_service.dart';
import 'package:dsys/services/gundem_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Provider pagination', () {
    test('ButceAktarimProvider sayfaları birleştirir', () async {
      final provider = ButceAktarimProvider(
        service: _FakeButceAktarimService([
          [_aktarim('1')],
          [_aktarim('2')],
        ]),
      );

      await provider.aktarimlariYukle();
      expect(provider.aktarimlar.map((e) => e.id), ['1']);
      expect(provider.hasMore, isTrue);

      await provider.dahaFazlaYukle();
      expect(provider.aktarimlar.map((e) => e.id), ['1', '2']);
      expect(provider.hasMore, isFalse);
    });

    test('EkOdemeProvider katsayı hesabı ve pagination çalışır', () async {
      final provider = EkOdemeProvider(
        service: _FakeEkOdemeService([
          [_ekOdeme('1')],
          [_ekOdeme('2')],
        ]),
      );

      await provider.ekOdemeleriYukle();
      await provider.dahaFazlaYukle();

      expect(provider.ekOdemeler, hasLength(2));
      expect(
        provider.katsayiHesapla(1000, const [
          EkOdemePersonel(
            personelId: 'p1',
            adSoyad: 'Ali Veli',
            unvan: 'Prof.',
            puan: 100,
            unvanKatsayisi: 1.0,
            hakedis: 0,
          ),
        ]),
        10.0,
      );
    });

    test('DisHekimligiProvider sayfalama durumunu korur', () async {
      final provider = DisHekimligiProvider(
        service: _FakeDisHekimligiService([
          [_disDagitim('1')],
          [_disDagitim('2')],
        ]),
      );

      await provider.dagitimlariYukle();
      await provider.dahaFazlaYukle();

      expect(provider.dagitimlar.map((e) => e.id), ['1', '2']);
      expect(provider.hasMore, isFalse);
    });

    test('GundemProvider sayfalama ve belge üretimini sürdürür', () async {
      final provider = GundemProvider(
        service: _FakeGundemService([
          [_toplanti('1')],
          [_toplanti('2')],
        ]),
      );

      await provider.toplantilariYukle();
      await provider.dahaFazlaYukle();
      await provider.toplantiYukle('1');

      expect(provider.toplantilar, hasLength(2));
      expect(provider.gundemBelgesiUret(), contains('TOPLANTI GÜNDEMİ'));
    });

    test('FaturaProvider sayfalar ve kuyruk sayısını günceller', () async {
      final provider = FaturaProvider(
        service: _FakeFaturaService([
          [_fatura('1')],
          [_fatura('2', durum: FaturaDurum.basildi)],
        ]),
      );

      await provider.faturalariYukle();
      expect(provider.kuyrukSayisi, 1);

      await provider.dahaFazlaYukle();
      expect(provider.faturalar, hasLength(2));
      expect(provider.hasMore, isFalse);
    });

    test('EvrakArsivProvider OCR sonucu ve pagination saklar', () async {
      final provider = EvrakArsivProvider(
        service: _FakeEvrakArsivService([
          [_evrak('1')],
          [_evrak('2')],
        ]),
      );

      await provider.evraklariYukle();
      await provider.dahaFazlaYukle();
      final sonuc = await provider.dosyadanOcrOku(
        dosyaBytes: Uint8List.fromList([1, 2, 3]),
        dosyaAdi: 'ust_yazi.pdf',
      );

      expect(provider.evraklar, hasLength(2));
      expect(sonuc?.baslik, 'OCR Başlık');
      expect(provider.sonOcrSonucu?.etiketler, contains('kurul'));
    });
  });
}

class _FakeButceAktarimService extends ButceAktarimService {
  _FakeButceAktarimService(this.pages);

  final List<List<ButceAktarimModel>> pages;
  int _index = 0;

  @override
  Future<PaginatedResult<ButceAktarimModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final items = _index < pages.length ? pages[_index] : <ButceAktarimModel>[];
    final hasMore = _index < pages.length - 1;
    _index++;
    return PaginatedResult(items: items, hasMore: hasMore);
  }
}

class _FakeEkOdemeService extends EkOdemeService {
  _FakeEkOdemeService(this.pages);

  final List<List<EkOdemeModel>> pages;
  int _index = 0;

  @override
  Future<PaginatedResult<EkOdemeModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final items = _index < pages.length ? pages[_index] : <EkOdemeModel>[];
    final hasMore = _index < pages.length - 1;
    _index++;
    return PaginatedResult(items: items, hasMore: hasMore);
  }
}

class _FakeDisHekimligiService extends DisHekimligiService {
  _FakeDisHekimligiService(this.pages);

  final List<List<DisHekimligiDagitimModel>> pages;
  int _index = 0;

  @override
  Future<PaginatedResult<DisHekimligiDagitimModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final items =
        _index < pages.length ? pages[_index] : <DisHekimligiDagitimModel>[];
    final hasMore = _index < pages.length - 1;
    _index++;
    return PaginatedResult(items: items, hasMore: hasMore);
  }
}

class _FakeGundemService extends GundemService {
  _FakeGundemService(this.pages);

  final List<List<ToplantiModel>> pages;
  int _index = 0;

  @override
  Future<PaginatedResult<ToplantiModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final items = _index < pages.length ? pages[_index] : <ToplantiModel>[];
    final hasMore = _index < pages.length - 1;
    _index++;
    return PaginatedResult(items: items, hasMore: hasMore);
  }

  @override
  Future<ToplantiModel?> getById(String id) async => _toplanti(id);
}

class _FakeFaturaService extends FaturaService {
  _FakeFaturaService(this.pages);

  final List<List<FaturaModel>> pages;
  int _index = 0;

  @override
  Future<PaginatedResult<FaturaModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final items = _index < pages.length ? pages[_index] : <FaturaModel>[];
    final hasMore = _index < pages.length - 1;
    _index++;
    return PaginatedResult(items: items, hasMore: hasMore);
  }
}

class _FakeEvrakArsivService extends EvrakArsivService {
  _FakeEvrakArsivService(this.pages);

  final List<List<EvrakModel>> pages;
  int _index = 0;

  @override
  Future<PaginatedResult<EvrakModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final items = _index < pages.length ? pages[_index] : <EvrakModel>[];
    final hasMore = _index < pages.length - 1;
    _index++;
    return PaginatedResult(items: items, hasMore: hasMore);
  }

  @override
  Future<EvrakOcrSonucu?> geminiOcrOku(
    Uint8List dosyaBytes,
    String dosyaAdi,
  ) async {
    return const EvrakOcrSonucu(
      baslik: 'OCR Başlık',
      evrakSayisi: 'E-42',
      evrakTarihi: '31.05.2026',
      icerikOzeti: 'Özet metni',
      etiketler: ['kurul', 'ödenek'],
      hamCevap: 'BASLIK: OCR Başlık',
    );
  }
}

ButceAktarimModel _aktarim(String id) => ButceAktarimModel(
      id: id,
      birimId: 'b$id',
      birimAd: 'Birim $id',
      kararTarihi: '31.05.2026',
      kararNo: '2026/$id',
      satirlar: const [
        ButceAktarimSatir(bolum: '03', madde: '03.02', artirilanTutar: 100),
      ],
    );

EkOdemeModel _ekOdeme(String id) => EkOdemeModel(
      id: id,
      birimId: 'b$id',
      birimAd: 'Birim $id',
      donem: '2026-Q2',
      katsayi: 10,
      toplamDagitilanTutar: 1000,
      toplamPuan: 100,
    );

DisHekimligiDagitimModel _disDagitim(String id) => DisHekimligiDagitimModel(
      id: id,
      birimId: 'b$id',
      birimAd: 'Diş Hekimliği',
      donem: '2026-Q2',
      toplamBrutGelir: 10000,
      akademikIdariTutar: 6000,
      yoneticiTutar: 2000,
      mesaiDisiTutar: 2000,
    );

ToplantiModel _toplanti(String id) => ToplantiModel(
      id: id,
      toplantiTarihi: '31.05.2026',
      toplantiNo: 'YK-$id',
      gundemMaddeleri: const [
        GundemMaddesi(siraNo: 1, baslik: 'Karar', tur: GundemTuru.diger),
      ],
    );

FaturaModel _fatura(String id, {FaturaDurum durum = FaturaDurum.bekleyen}) =>
    FaturaModel(
      id: id,
      birimId: 'b$id',
      birimAd: 'UBATAM',
      firmaUnvan: 'Firma $id',
      hizmetDetay: 'Hizmet',
      tutar: 100,
      kdvTutar: 20,
      toplamTutar: 120,
      durum: durum,
    );

EvrakModel _evrak(String id) => EvrakModel(
      id: id,
      baslik: 'Evrak $id',
      evrakTuru: EvrakTuru.ustYazi,
    );
