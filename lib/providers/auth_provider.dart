import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication durumunu yöneten Provider.
///
/// Auth durumunu dinler, giriş/çıkış işlemlerini yönetir ve
/// hata durumlarını kullanıcı dostu mesajlara dönüştürür.
class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuth _auth;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  /// Mevcut oturum açmış kullanıcı. Null ise oturum yok.
  User? get user => _user;

  /// Kimlik doğrulama işlemi devam ediyor mu?
  bool get isLoading => _isLoading;

  /// Son hata mesajı (kullanıcı dostu, Türkçe).
  String? get errorMessage => _errorMessage;

  /// Kullanıcı oturum açmış mı?
  bool get isAuthenticated => _user != null;

  void _onAuthStateChanged(User? user) {
    _user = user;
    _isLoading = false;
    notifyListeners();
  }

  /// E-posta ve şifre ile giriş yapar.
  ///
  /// Başarılı olursa `true`, hata oluşursa `false` döner.
  /// Hata mesajı [errorMessage] üzerinden okunabilir.
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Oturumu kapatır.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _errorMessage = 'Çıkış yapılırken bir hata oluştu.';
      notifyListeners();
    }
  }

  /// Hata mesajını temizler.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Firebase Auth hata kodlarını Türkçe kullanıcı dostu mesajlara çevirir.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresine ait bir hesap bulunamadı.';
      case 'wrong-password':
        return 'Girilen şifre hatalı.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmıştır. Yönetici ile iletişime geçin.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen bir süre bekleyip tekrar deneyin.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Giriş yapılamadı. Lütfen tekrar deneyin.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
