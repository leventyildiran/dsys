import 'package:flutter_test/flutter_test.dart';
import 'package:dsys/services/firestore_service.dart';

void main() {
  group('FirestoreService - Multi-tenant', () {
    test('activeUniversiteId varsayılan olarak usak', () {
      expect(FirestoreService.activeUniversiteId, equals('usak'));
    });

    test('activeUniversiteId değiştirilebilir', () {
      FirestoreService.activeUniversiteId = 'ankara';
      expect(FirestoreService.activeUniversiteId, equals('ankara'));

      // Temizle
      FirestoreService.activeUniversiteId = 'usak';
    });
  });
}
