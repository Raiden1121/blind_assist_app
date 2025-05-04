// =======================================================
// firebase_options.dart
// 此檔案由 FlutterFire CLI 自動生成
// 功能：提供 Firebase 的平台設定選項（FirebaseOptions）
// 用法：傳入 Firebase.initializeApp(options: ...) 時使用
// =======================================================

// FlutterFire CLI 會自動產生 ignore_for_file: type=lint
// （跳過 lint 檢查）
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// 預設的 FirebaseOptions 設定
///
/// 使用方式：
/// ```dart
/// import 'firebase_options.dart';
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  /// 根據目前執行平台（Android / iOS）自動回傳對應的 FirebaseOptions
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // 🚩 若為 Web 平台 → 尚未設定 → 丟出錯誤
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // ✅ Android 平台 → 回傳 Android 設定
        return android;
      case TargetPlatform.iOS:
        // ✅ iOS 平台 → 回傳 iOS 設定
        return ios;
      case TargetPlatform.macOS:
        // 🚩 macOS 尚未設定 → 丟出錯誤
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        // 🚩 Windows 尚未設定 → 丟出錯誤
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        // 🚩 Linux 尚未設定 → 丟出錯誤
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        // 🚩 其他未知平台 → 丟出錯誤
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Android 平台專用的 FirebaseOptions
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCZsbQv35Fa3Zmn5fU4S7o9Bz7wpluNX0', // Firebase API Key
    appId: '1:617941879669:android:874e8922650e5247fa213c', // Firebase App ID
    messagingSenderId: '617941879669', // Firebase Cloud Messaging Sender ID
    projectId: 'cybolts', // Firebase Project ID
    databaseURL:
        'https://cybolts-default-rtdb.asia-southeast1.firebasedatabase.app', // Realtime Database URL
    storageBucket: 'cybolts.firebasestorage.app', // Cloud Storage Bucket
  );

  /// iOS 平台專用的 FirebaseOptions
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3SoLGX4zeyxeIMf6clkknjyGghqxR46Q',
    appId: '1:617941879669:ios:d40a6664cde8ff48fa213c',
    messagingSenderId: '617941879669',
    projectId: 'cybolts',
    databaseURL:
        'https://cybolts-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'cybolts.firebasestorage.app',
    iosBundleId: 'com.blindAssistApp', // iOS App 的 Bundle ID
  );
}
