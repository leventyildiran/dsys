import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/paginated_result.dart';
import '../models/yk_karar_model.dart';
import 'firestore_service.dart';

/// YK Karar Merkezi servis katmanı.
///
/// Firestore yolu: `ykKararlari/{kararId}`
class YkKararService {
  YkKararService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const String _collection = 'ykKararlari';

  /// Tüm kararları getirir.
  Future<List<YkKararModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(_collection);
      return snapshot.docs
          .map((doc) => YkKararModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[YkKararService.getAll] Hata: $e');
      return [];
    }
  }

  /// Sayfalı olarak kararları getirir.
  Future<PaginatedResult<YkKararModel,
      QueryDocumentSnapshot<Map<String, dynamic>>>> getPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    String? toplantiId,
  }) async {
    try {
      final page = await _service.getPage(
        _collection,
        limit: limit,
        startAfterDocument: startAfterDocument,
        queryBuilder: (ref) {
          var query = ref.orderBy('olusturmaTarihi', descending: true);
          if (toplantiId != null && toplantiId.isNotEmpty) {
            query = query.where('toplantiId', isEqualTo: toplantiId);
          }
          return query;
        },
      );
      return PaginatedResult(
        items: page.docs
            .map((doc) => YkKararModel.fromMap(doc.id, doc.data()))
            .toList(),
        hasMore: page.hasMore,
        nextCursor: page.lastDocument,
      );
    } catch (e) {
      debugPrint('[YkKararService.getPage] Hata: $e');
      return const PaginatedResult(items: [], hasMore: false);
    }
  }

  /// Belirli bir toplantıya ait tüm kararları getirir.
  Future<List<YkKararModel>> getByToplanti(String toplantiId) async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'toplantiId',
        isEqualTo: toplantiId,
      );
      final list = snapshot.docs
          .map((doc) => YkKararModel.fromMap(doc.id, doc.data()))
          .toList();
      // Karar numarasına göre sıralayalım
      list.sort((a, b) => a.kararNo.compareTo(b.kararNo));
      return list;
    } catch (e) {
      debugPrint('[YkKararService.getByToplanti] Hata: $e');
      return [];
    }
  }

  /// Karar no'ya göre en son karar numarasını bulmak veya üretmek için
  /// toplantı bazlı kararları sorgular.
  Future<String> sonrakiKararNoUret(String toplantiNo) async {
    try {
      final snapshot = await _service.where(
        _collection,
        field: 'toplantiNo',
        isEqualTo: toplantiNo,
      );
      final list = snapshot.docs
          .map((doc) => YkKararModel.fromMap(doc.id, doc.data()))
          .toList();
      if (list.isEmpty) {
        return '$toplantiNo-01';
      }
      
      // En son karar no'yu bulalım
      list.sort((a, b) => a.kararNo.compareTo(b.kararNo));
      final sonKararNo = list.last.kararNo;
      final parcalar = sonKararNo.split('-');
      if (parcalar.length > 1) {
        final sira = int.tryParse(parcalar.last) ?? 0;
        final yeniSira = sira + 1;
        final yeniSiraStr = yeniSira.toString().padLeft(2, '0');
        return '$toplantiNo-$yeniSiraStr';
      }
      return '$toplantiNo-01';
    } catch (e) {
      debugPrint('[YkKararService.sonrakiKararNoUret] Hata: $e');
      return '$toplantiNo-01';
    }
  }

  /// Tekil karar kaydı getirir.
  Future<YkKararModel?> getById(String id) async {
    try {
      final doc = await _service.get(_collection, id);
      if (!doc.exists || doc.data() == null) return null;
      return YkKararModel.fromMap(id, doc.data()!);
    } catch (e) {
      debugPrint('[YkKararService.getById] Hata: $e');
      return null;
    }
  }

  /// Yeni karar kaydı oluşturur.
  Future<String> create(YkKararModel model) async {
    try {
      final data = model.toMap();
      data['olusturmaTarihi'] = DateTime.now().toIso8601String();
      final docRef = await _service.add(_collection, data);
      return docRef.id;
    } catch (e) {
      debugPrint('[YkKararService.create] Hata: $e');
      rethrow;
    }
  }

  /// Karar kaydını günceller.
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(_collection, id, data);
    } catch (e) {
      debugPrint('[YkKararService.update] Hata: $e');
      rethrow;
    }
  }

  /// Karar kaydını siler.
  Future<void> delete(String id) async {
    try {
      await _service.delete(_collection, id);
    } catch (e) {
      debugPrint('[YkKararService.delete] Hata: $e');
      rethrow;
    }
  }

  /// Toplantıya ait Karar Defteri (.txt formatında) metnini üretir.
  String kararDefteriUret(String toplantiNo, String toplantiTarihi, List<YkKararModel> kararlar) {
    final buffer = StringBuffer();
    buffer.writeln('UŞAK ÜNİVERSİTESİ DÖNER SERMAYE İŞLETMESİ');
    buffer.writeln('YÜRÜTME KURULU KARAR DEFTERİ');
    buffer.writeln('═' * 60);
    buffer.writeln();
    buffer.writeln('Toplantı No     : $toplantiNo');
    buffer.writeln('Toplantı Tarihi : $toplantiTarihi');
    buffer.writeln('Toplam Karar    : ${kararlar.length}');
    buffer.writeln();
    buffer.writeln('─' * 60);
    buffer.writeln();

    for (final karar in kararlar) {
      buffer.writeln('KARAR NO: ${karar.kararNo}');
      buffer.writeln('KONU    : ${karar.baslik}');
      buffer.writeln('BİRİM   : ${karar.birimAd}');
      buffer.writeln();
      buffer.writeln('KARAR METNİ:');
      buffer.writeln(karar.kararMetni);
      buffer.writeln();
      buffer.writeln('─' * 60);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
