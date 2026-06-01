import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/paginated_result.dart';
import '../models/fatura_model.dart';
import 'firestore_service.dart';

/// Fatura basım ve PDF önizleme servis katmanı.
///
/// Firestore yolu: `faturalar/{faturaId}`
class FaturaService {
  FaturaService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const String _collection = 'faturalar';

  /// Tüm faturaları getirir.
  Future<List<FaturaModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(_collection);
      return snapshot.docs
          .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FaturaService.getAll] Hata: $e');
      return [];
    }
  }

  Future<PaginatedResult<FaturaModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    try {
      final page = await _service.getPage(
        _collection,
        limit: limit,
        startAfterDocument: startAfterDocument,
        queryBuilder: (ref) => ref.orderBy('olusturmaTarihi', descending: true),
      );
      return PaginatedResult(
        items: page.docs
            .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
            .toList(),
        hasMore: page.hasMore,
        nextCursor: page.lastDocument,
      );
    } catch (e) {
      debugPrint('[FaturaService.getPage] Hata: $e');
      return const PaginatedResult(items: [], hasMore: false);
    }
  }

  /// Birime göre faturaları getirir.
  Future<List<FaturaModel>> getByBirim(String birimId) async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'birimId',
        isEqualTo: birimId,
      );
      return snapshot.docs
          .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FaturaService.getByBirim] Hata: $e');
      return [];
    }
  }

  /// Bekleyen faturaları getirir (kuyruk).
  Future<List<FaturaModel>> getBekleyenler() async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'durum',
        isEqualTo: FaturaDurum.bekleyen.value,
      );
      return snapshot.docs
          .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FaturaService.getBekleyenler] Hata: $e');
      return [];
    }
  }

  /// Tekil fatura getirir.
  Future<FaturaModel?> getById(String id) async {
    try {
      final doc = await _service.get(_collection, id);
      if (!doc.exists || doc.data() == null) return null;
      return FaturaModel.fromMap(id, doc.data()!);
    } catch (e) {
      debugPrint('[FaturaService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni fatura kaydı oluşturur.
  Future<String> create(FaturaModel model) async {
    try {
      final data = model.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_collection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[FaturaService.create] Hata: $e');
      rethrow;
    }
  }

  /// Toplu fatura oluşturur (metin ayrıştırma sonrası).
  Future<List<String>> topluOlustur(List<FaturaModel> faturalar) async {
    try {
      final ids = <String>[];
      for (final fatura in faturalar) {
        final id = await create(fatura);
        ids.add(id);
      }
      return ids;
    } catch (e) {
      debugPrint('[FaturaService.topluOlustur] Hata: $e');
      rethrow;
    }
  }

  /// Fatura kaydını günceller.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(_collection, id, data);
    } catch (e) {
      debugPrint('[FaturaService.update] Hata: $e');
      rethrow;
    }
  }

  /// Fatura durumunu değiştirir.
  Future<void> durumDegistir(String id, FaturaDurum yeniDurum) async {
    await update(id, {'durum': yeniDurum.value});
  }

  /// Faturayı basıldı olarak işaretler.
  Future<void> basildiIsaretle(String id) async {
    await durumDegistir(id, FaturaDurum.basildi);
  }

  /// Metin ayrıştırma — gelen fatura taleplerini parse eder.
  ///
  /// Regex tabanlı kural bazlı ayrıştırma (Script-First).
  /// Düzensiz metinler için AI fallback gerekir.
  List<FaturaParseSonuc> metinAyristir(String metin) {
    final sonuclar = <FaturaParseSonuc>[];
    final satirlar = metin.split('\n').where((s) => s.trim().isNotEmpty);

    // Basit regex bazlı ayrıştırma
    final firmaRegex = RegExp(r'(?:firma|şirket|unvan)\s*[:\-]\s*(.+)', caseSensitive: false);
    final tutarRegex = RegExp(r'(?:tutar|ücret|bedel)\s*[:\-]\s*([\d.,]+)', caseSensitive: false);
    final hizmetRegex = RegExp(r'(?:hizmet|analiz|tahlil|test)\s*[:\-]\s*(.+)', caseSensitive: false);

    String? mevcutFirma;
    String? mevcutHizmet;
    double? mevcutTutar;

    for (final satir in satirlar) {
      final firmaMatch = firmaRegex.firstMatch(satir);
      final tutarMatch = tutarRegex.firstMatch(satir);
      final hizmetMatch = hizmetRegex.firstMatch(satir);

      if (firmaMatch != null) {
        // Önceki kaydı kaydet
        if (mevcutFirma != null) {
          sonuclar.add(FaturaParseSonuc(
            firmaUnvan: mevcutFirma,
            hizmetDetay: mevcutHizmet ?? '',
            tutar: mevcutTutar ?? 0,
          ));
        }
        mevcutFirma = firmaMatch.group(1)?.trim();
        mevcutHizmet = null;
        mevcutTutar = null;
      }

      if (hizmetMatch != null) {
        mevcutHizmet = hizmetMatch.group(1)?.trim();
      }

      if (tutarMatch != null) {
        final tutarStr = tutarMatch.group(1)?.replaceAll('.', '').replaceAll(',', '.');
        mevcutTutar = double.tryParse(tutarStr ?? '0');
      }
    }

    // Son kaydı ekle
    if (mevcutFirma != null) {
      sonuclar.add(FaturaParseSonuc(
        firmaUnvan: mevcutFirma,
        hizmetDetay: mevcutHizmet ?? '',
        tutar: mevcutTutar ?? 0,
      ));
    }

    return sonuclar;
  }

  /// Fatura kaydını siler.
  Future<void> delete(String id) async {
    try {
      await _service.delete(_collection, id);
    } catch (e) {
      debugPrint('[FaturaService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Gerçek zamanlı dinleme.
  Stream<List<FaturaModel>> stream() {
    return _service.stream(_collection).map((snapshot) => snapshot.docs
        .map((doc) => FaturaModel.fromMap(doc.id, doc.data()))
        .toList());
  }
}

/// Metin ayrıştırma sonucu.
class FaturaParseSonuc {
  const FaturaParseSonuc({
    required this.firmaUnvan,
    required this.hizmetDetay,
    required this.tutar,
  });

  final String firmaUnvan;
  final String hizmetDetay;
  final double tutar;
}
