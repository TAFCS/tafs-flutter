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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can re-run the FlutterFire CLI again to afford macos support',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can re-run the FlutterFire CLI again to afford windows support',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can re-run the FlutterFire CLI again to afford linux support',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB2-rmiE1ZpL3Z31mEzp4DFtGxq-gS4ROo',
    appId: '1:888112026414:web:tafs_web',
    messagingSenderId: '888112026414',
    projectId: 'tafs-bb6c4',
    authDomain: 'tafs-bb6c4.firebaseapp.com',
    storageBucket: 'tafs-bb6c4.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2-rmiE1ZpL3Z31mEzp4DFtGxq-gS4ROo',
    appId: '1:888112026414:android:ffbc38f61ecc24b46e60bf',
    messagingSenderId: '888112026414',
    projectId: 'tafs-bb6c4',
    storageBucket: 'tafs-bb6c4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATr_MO-Kikq5LSQ8iP7bU3AvDIarOp81E',
    appId: '1:888112026414:ios:6f68c08cf2a10f956e60bf',
    messagingSenderId: '888112026414',
    projectId: 'tafs-bb6c4',
    storageBucket: 'tafs-bb6c4.firebasestorage.app',
    iosBundleId: 'com.tafs.app',
  );
}
