import 'package:flutter_test/flutter_test.dart';
import 'package:dsys/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap doğru şekilde parse eder', () {
      final map = {
        'displayName': 'Test User',
        'email': 'test@example.com',
        'role': 'super_admin',
        'birimId': 'birim1',
        'universiteId': 'usak',
        'aktif': true,
      };

      final user = UserModel.fromMap('uid123', map);

      expect(user.uid, equals('uid123'));
      expect(user.displayName, equals('Test User'));
      expect(user.email, equals('test@example.com'));
      expect(user.role, equals(UserRole.superAdmin));
      expect(user.birimId, equals('birim1'));
      expect(user.universiteId, equals('usak'));
      expect(user.aktif, isTrue);
    });

    test('fromMap eksik alanlarla varsayılan değerler', () {
      final map = <String, dynamic>{};
      final user = UserModel.fromMap('uid456', map);

      expect(user.displayName, equals(''));
      expect(user.email, equals(''));
      expect(user.role, equals(UserRole.birimSekreteri));
      expect(user.birimId, isNull);
      expect(user.aktif, isTrue);
    });

    test('toMap doğru dönüşüm yapar', () {
      const user = UserModel(
        uid: 'uid789',
        displayName: 'Admin',
        email: 'admin@dsys.com',
        role: UserRole.ykSekreteri,
        birimId: null,
        universiteId: 'usak',
        aktif: true,
      );

      final map = user.toMap();

      expect(map['displayName'], equals('Admin'));
      expect(map['role'], equals('yk_sekreteri'));
      expect(map['universiteId'], equals('usak'));
    });

    test('copyWith yeni değerlerle kopyalar', () {
      const original = UserModel(
        uid: 'uid1',
        displayName: 'Original',
        email: 'o@test.com',
        role: UserRole.birimMuduru,
      );

      final copy = original.copyWith(
        displayName: 'Updated',
        role: UserRole.superAdmin,
      );

      expect(copy.uid, equals('uid1')); // uid değişmez
      expect(copy.displayName, equals('Updated'));
      expect(copy.role, equals(UserRole.superAdmin));
      expect(copy.email, equals('o@test.com')); // değişmemiş alanlar korunur
    });
  });

  group('UserRole', () {
    test('fromString doğru enum değeri döner', () {
      expect(UserRole.fromString('super_admin'), equals(UserRole.superAdmin));
      expect(UserRole.fromString('yk_sekreteri'), equals(UserRole.ykSekreteri));
      expect(UserRole.fromString('birim_muduru'), equals(UserRole.birimMuduru));
      expect(UserRole.fromString('muhasebe'), equals(UserRole.muhasebe));
    });

    test('fromString bilinmeyen değerde varsayılan döner', () {
      expect(UserRole.fromString('unknown'), equals(UserRole.birimSekreteri));
    });

    test('isGlobal kontrolü', () {
      expect(UserRole.superAdmin.isGlobal, isTrue);
      expect(UserRole.ykSekreteri.isGlobal, isTrue);
      expect(UserRole.birimMuduru.isGlobal, isFalse);
      expect(UserRole.birimSekreteri.isGlobal, isFalse);
      expect(UserRole.muhasebe.isGlobal, isFalse);
    });

    test('displayName mevcut', () {
      expect(UserRole.superAdmin.displayName, equals('Süper Admin'));
      expect(UserRole.muhasebe.displayName, equals('Muhasebe'));
    });
  });
}
