// =======================================================
// auth_service.dart
// ✅ 功能說明：
// 1️⃣ 提供 Firebase Authentication 的帳號操作封裝
// 2️⃣ ✅ Email/密碼 註冊 & 登入
// 3️⃣ ✅ 登出功能
// 4️⃣ ❌ Google / Apple 登入 → 已註解（暫不啟用）
// =======================================================

import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // ✅ 註解掉 Google Sign-in
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // ✅ 註解掉 Apple Sign-in

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth 實例
  // static final GoogleSignIn _googleSignIn = GoogleSignIn(); // ✅ 註解掉 Google Sign-in 實例

  /// 🔄 監聽使用者登入狀態變化
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ✅ Email/Password 註冊新帳號
  /// [email] 使用者 Email
  /// [password] 使用者密碼
  /// 回傳：UserCredential（登入憑證）
  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  /// ✅ Email/Password 登入
  /// [email] 使用者 Email
  /// [password] 使用者密碼
  /// 回傳：UserCredential（登入憑證）
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /*
  // ❌ Google 登入功能（已註解，不使用）
  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: '使用者取消了 Google 登入',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ❌ Apple 登入功能（已註解，不使用）
  static Future<UserCredential> signInWithApple() async {
    final appleCred = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );
    final oauthCred = OAuthProvider('apple.com').credential(
      idToken: appleCred.identityToken,
      accessToken: appleCred.authorizationCode,
    );
    return _auth.signInWithCredential(oauthCred);
  }
  */

  /// ✅ 登出功能
  /// （因未使用 Google sign-in → 無需另外登出 Google）
  static Future<void> signOut() async {
    // await _googleSignIn.signOut().catchError((_) {}); // ✅ 註解掉 Google signOut
    await _auth.signOut(); // 登出 Firebase
  }
}
