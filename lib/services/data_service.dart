import '../models/birim_model.dart';
import '../models/personel_model.dart';
import '../models/firma_model.dart';
import '../models/danismanlik_model.dart';
import '../models/faaliyet_tanim_model.dart';
import '../models/sistem_ayarlari_model.dart';
import 'firestore_service.dart';

/// Birimler koleksiyonu servisi.
class BirimService {
  BirimService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const _path = 'birimler';

  Future<List<BirimModel>> getAll({bool onlyActive = true}) async {
    try {
      final snapshot = await _service.getAll(
        _path,
        queryBuilder: onlyActive
            ? (ref) => ref.where('aktif', isEqualTo: true)
            : null,
      );
      return snapshot.docs
          .map((doc) => BirimModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<BirimModel?> getById(String id) async {
    try {
      final doc = await _service.get(_path, id);
      if (!doc.exists || doc.data() == null) return null;
      return BirimModel.fromMap(id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<String> create(BirimModel birim) async {
    return _service.create(_path, birim.toMap());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _service.update(_path, id, data);
  }

  Stream<List<BirimModel>> stream({bool onlyActive = true}) {
    return _service
        .stream(
          _path,
          queryBuilder: onlyActive
              ? (ref) => ref.where('aktif', isEqualTo: true)
              : null,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => BirimModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}

/// Personel koleksiyonu servisi.
class PersonelService {
  PersonelService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const _path = 'personel';

  Future<List<PersonelModel>> getAll({String? birimId, bool onlyActive = true}) async {
    try {
      final snapshot = await _service.getAll(
        _path,
        queryBuilder: (ref) {
          var query = ref.where('aktif', isEqualTo: onlyActive ? true : null);
          if (onlyActive) {
            query = ref.where('aktif', isEqualTo: true);
          }
          if (birimId != null) {
            query = query.where('birimId', isEqualTo: birimId);
          }
          return query;
        },
      );
      return snapshot.docs
          .map((doc) => PersonelModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<PersonelModel?> getById(String id) async {
    try {
      final doc = await _service.get(_path, id);
      if (!doc.exists || doc.data() == null) return null;
      return PersonelModel.fromMap(id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<String> create(PersonelModel personel) async {
    return _service.create(_path, personel.toMap());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _service.update(_path, id, data);
  }

  Stream<List<PersonelModel>> stream({String? birimId}) {
    return _service
        .stream(
          _path,
          queryBuilder: (ref) {
            var query = ref.where('aktif', isEqualTo: true);
            if (birimId != null) {
              query = query.where('birimId', isEqualTo: birimId);
            }
            return query;
          },
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => PersonelModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}

/// Firma koleksiyonu servisi.
class FirmaService {
  FirmaService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const _path = 'firmalar';

  Future<List<FirmaModel>> getAll({bool onlyActive = true}) async {
    try {
      final snapshot = await _service.getAll(
        _path,
        queryBuilder: onlyActive
            ? (ref) => ref.where('aktif', isEqualTo: true)
            : null,
      );
      return snapshot.docs
          .map((doc) => FirmaModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> create(FirmaModel firma) async {
    return _service.create(_path, firma.toMap());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _service.update(_path, id, data);
  }

  Stream<List<FirmaModel>> stream() {
    return _service
        .stream(_path, queryBuilder: (ref) => ref.where('aktif', isEqualTo: true))
        .map((snapshot) => snapshot.docs
            .map((doc) => FirmaModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}

/// Danışmanlık koleksiyonu servisi.
class DanismanlikService {
  DanismanlikService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const _path = 'danismanliklar';

  Future<List<DanismanlikModel>> getAll({String? birimId}) async {
    try {
      final snapshot = await _service.getAll(
        _path,
        queryBuilder: birimId != null
            ? (ref) => ref.where('birimId', isEqualTo: birimId)
            : null,
      );
      return snapshot.docs
          .map((doc) => DanismanlikModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<DanismanlikModel?> getById(String id) async {
    try {
      final doc = await _service.get(_path, id);
      if (!doc.exists || doc.data() == null) return null;
      return DanismanlikModel.fromMap(id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<String> create(DanismanlikModel danismanlik) async {
    return _service.create(_path, danismanlik.toMap());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _service.update(_path, id, data);
  }

  Stream<List<DanismanlikModel>> stream({String? birimId}) {
    return _service
        .stream(
          _path,
          queryBuilder: birimId != null
              ? (ref) => ref.where('birimId', isEqualTo: birimId)
              : null,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => DanismanlikModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}

/// Faaliyet tanımları koleksiyonu servisi.
class FaaliyetTanimService {
  FaaliyetTanimService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const _path = 'faaliyetTanimlari';

  Future<List<FaaliyetTanimModel>> getAll() async {
    try {
      final snapshot = await _service.getAll(
        _path,
        queryBuilder: (ref) => ref.where('aktif', isEqualTo: true),
      );
      return snapshot.docs
          .map((doc) => FaaliyetTanimModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> create(FaaliyetTanimModel faaliyet) async {
    return _service.create(_path, faaliyet.toMap());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _service.update(_path, id, data);
  }
}

/// Sistem ayarları servisi.
class SistemAyarlariService {
  SistemAyarlariService({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService();

  final FirestoreService _service;
  static const _path = 'sistemAyarlari';
  static const _docId = 'genel';

  Future<SistemAyarlariModel?> get() async {
    try {
      final doc = await _service.get(_path, _docId);
      if (!doc.exists || doc.data() == null) return null;
      return SistemAyarlariModel.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> update(Map<String, dynamic> data) async {
    await _service.set(_path, _docId, data);
  }

  Stream<SistemAyarlariModel?> stream() {
    return _service.collection(_path).doc(_docId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SistemAyarlariModel.fromMap(doc.data()!);
    });
  }
}
