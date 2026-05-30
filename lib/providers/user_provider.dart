import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

/// Kullanıcı profil ve rol yönetimi Provider'ı.
///
/// AuthProvider'dan gelen auth state'e göre Firestore'dan
/// kullanıcı profilini yükler ve rol bazlı erişim sağlar.
class UserProvider extends ChangeNotifier {
  UserProvider({
    required AuthProvider authProvider,
    UserService? userService,
  })  : _authProvider = authProvider,
        _userService = userService ?? UserService() {
    _authProvider.addListener(_onAuthChanged);
    // İlk yükleme
    if (_authProvider.isAuthenticated) {
      _loadUserProfile();
    }
  }

  final AuthProvider _authProvider;
  final UserService _userService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  /// Mevcut kullanıcının profil bilgisi.
  UserModel? get currentUser => _currentUser;

  /// Profil yükleniyor mu?
  bool get isLoading => _isLoading;

  /// Hata mesajı.
  String? get errorMessage => _errorMessage;

  /// Kullanıcının rolü.
  UserRole? get currentRole => _currentUser?.role;

  /// Global yetki var mı? (SuperAdmin veya YK Sekreteri)
  bool get hasGlobalAccess => _currentUser?.role.isGlobal ?? false;

  /// Kullanıcının bağlı olduğu birim ID'si.
  String? get currentBirimId => _currentUser?.birimId;

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      _loadUserProfile();
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _userService.getUser(uid);
      if (_currentUser == null) {
        _errorMessage = 'Kullanıcı profili bulunamadı. Yönetici ile iletişime geçin.';
      }
    } catch (e) {
      _errorMessage = 'Profil yüklenirken hata oluştu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı profilini yeniden yükler.
  Future<void> refresh() async {
    await _loadUserProfile();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
