import 'package:cloud_firestore/cloud_firestore.dart';

/// Tüm Firestore servislerinin temel sınıfı.
///
/// Generic CRUD işlemlerini sağlar. Multi-tenant yapıyı destekler.
/// `universiteler/{universiteId}` kök yolu altında çalışır.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, String? universiteId})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _universiteId = universiteId ?? _defaultUniversiteId;

  final FirebaseFirestore _firestore;
  final String _universiteId;

  /// Varsayılan üniversite ID'si.
  static const String _defaultUniversiteId = 'usak';

  /// Aktif üniversite ID'sini global olarak ayarlar.
  /// Uygulama başlangıcında kullanıcı profili yüklendiğinde çağrılır.
  static String _activeUniversiteId = _defaultUniversiteId;
  static String get activeUniversiteId => _activeUniversiteId;
  static set activeUniversiteId(String value) {
    _activeUniversiteId = value;
  }

  /// Üniversite kök koleksiyon referansı.
  DocumentReference get universiteRef =>
      _firestore.collection('universiteler').doc(_universiteId);

  /// Belirli bir koleksiyonun referansını döner.
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      universiteRef.collection(path);

  /// Tek bir doküman oluşturur. ID otomatik atanır.
  Future<String> create(String collectionPath, Map<String, dynamic> data) async {
    final docRef = await collection(collectionPath).add(data);
    return docRef.id;
  }

  /// Belirli ID ile doküman oluşturur/günceller.
  Future<void> set(
    String collectionPath,
    String docId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    await collection(collectionPath).doc(docId).set(data, SetOptions(merge: merge));
  }

  /// Dokümanı günceller (sadece belirtilen alanlar).
  Future<void> update(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await collection(collectionPath).doc(docId).update(data);
  }

  /// Tek bir dokümanı getirir.
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
    String collectionPath,
    String docId,
  ) async {
    return collection(collectionPath).doc(docId).get();
  }

  /// Koleksiyondaki tüm dokümanları getirir (filtreleme opsiyonel).
  Future<QuerySnapshot<Map<String, dynamic>>> getAll(
    String collectionPath, {
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>>)?
        queryBuilder,
  }) async {
    final ref = collection(collectionPath);
    if (queryBuilder != null) {
      return queryBuilder(ref).get() as Future<QuerySnapshot<Map<String, dynamic>>>;
    }
    return ref.get();
  }

  /// Koleksiyonu gerçek zamanlı dinler.
  Stream<QuerySnapshot<Map<String, dynamic>>> stream(
    String collectionPath, {
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>>)?
        queryBuilder,
  }) {
    final ref = collection(collectionPath);
    if (queryBuilder != null) {
      return queryBuilder(ref).snapshots()
          as Stream<QuerySnapshot<Map<String, dynamic>>>;
    }
    return ref.snapshots();
  }

  /// Dokümanı siler.
  Future<void> delete(String collectionPath, String docId) async {
    await collection(collectionPath).doc(docId).delete();
  }

  /// Tek bir doküman ekler ve referansını döner.
  Future<DocumentReference<Map<String, dynamic>>> add(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    return collection(collectionPath).add(data);
  }

  /// Basit alan bazlı filtreleme (where sorgusu).
  Future<QuerySnapshot<Map<String, dynamic>>> where(
    String collectionPath, {
    required String field,
    required dynamic isEqualTo,
  }) async {
    return collection(collectionPath)
        .where(field, isEqualTo: isEqualTo)
        .get();
  }

  /// Yeni bir WriteBatch oluşturur (toplu yazma işlemleri için).
  WriteBatch batch() => _firestore.batch();

  /// Global users koleksiyonu (üniversite altında değil, kök seviyede).
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection('users');
}
