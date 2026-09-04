import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD70eo7s_CGZxne_1nKPKAHU76t9x1fxfM',
    appId: '1:240257650648:android:a0f19a192b3acf0e972cad',
    messagingSenderId: '240257650648',
    projectId: 'sattelite-view-by-arsalan',
    authDomain: 'sattelite-view-by-arsalan.firebaseapp.com',
    storageBucket: 'sattelite-view-by-arsalan.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD70eo7s_CGZxne_1nKPKAHU76t9x1fxfM',
    appId: '1:240257650648:android:a0f19a192b3acf0e972cad',
    messagingSenderId: '240257650648',
    projectId: 'sattelite-view-by-arsalan',
    storageBucket: 'sattelite-view-by-arsalan.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAGYGB1Lj5JLZ6rmlRm6DuR9tHGQhzL9KI',
    appId: '1:240257650648:ios:a5dbb27e1aed7e8b972cad',
    messagingSenderId: '240257650648',
    projectId: 'sattelite-view-by-arsalan',
    storageBucket: 'sattelite-view-by-arsalan.firebasestorage.app',
    iosBundleId: 'com.maps.sateliteview',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAGYGB1Lj5JLZ6rmlRm6DuR9tHGQhzL9KI',
    appId: '1:240257650648:ios:a5dbb27e1aed7e8b972cad',
    messagingSenderId: '240257650648',
    projectId: 'sattelite-view-by-arsalan',
    storageBucket: 'sattelite-view-by-arsalan.firebasestorage.app',
    iosBundleId: 'com.maps.sateliteview',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD70eo7s_CGZxne_1nKPKAHU76t9x1fxfM',
    appId: '1:240257650648:android:a0f19a192b3acf0e972cad',
    messagingSenderId: '240257650648',
    projectId: 'sattelite-view-by-arsalan',
    storageBucket: 'sattelite-view-by-arsalan.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyD70eo7s_CGZxne_1nKPKAHU76t9x1fxfM',
    appId: '1:240257650648:android:a0f19a192b3acf0e972cad',
    messagingSenderId: '240257650648',
    projectId: 'sattelite-view-by-arsalan',
    storageBucket: 'sattelite-view-by-arsalan.firebasestorage.app',
  );
}
