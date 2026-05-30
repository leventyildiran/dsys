import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase yapılandırma sınıfı.
///
/// Bu dosya `flutterfire configure` komutuyla otomatik oluşturulmalıdır.
/// Aşağıdaki değerler placeholder'dır; gerçek proje bilgileriyle
/// güncellenmelidir.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions Linux için yapılandırılmamıştır.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platform için yapılandırılmamıştır.',
        );
    }
  }

  // TODO: flutterfire configure çalıştırıldıktan sonra gerçek değerlerle güncellenecek.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dsys-usak',
    authDomain: 'dsys-usak.firebaseapp.com',
    storageBucket: 'dsys-usak.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dsys-usak',
    storageBucket: 'dsys-usak.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dsys-usak',
    storageBucket: 'dsys-usak.appspot.com',
    iosBundleId: 'com.usak.dsys',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: '1:000000000000:macos:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dsys-usak',
    storageBucket: 'dsys-usak.appspot.com',
    iosBundleId: 'com.usak.dsys',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dsys-usak',
    authDomain: 'dsys-usak.firebaseapp.com',
    storageBucket: 'dsys-usak.appspot.com',
  );
}
