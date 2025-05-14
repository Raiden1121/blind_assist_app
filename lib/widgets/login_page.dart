// =======================================================
// login_page.dart
// 此檔案實作「登入／註冊畫面」
// ✅ 功能：
// 1️⃣ 使用 Email / 密碼登入 Firebase
// 2️⃣ 使用 Email / 密碼註冊新帳號
// 3️⃣ 顯示登入／註冊過程的錯誤與 loading 狀態
// =======================================================

import 'package:flutter/material.dart';
import 'package:blind_assist_app/services/auth_service.dart'; // 自定義 AuthService
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthException

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailCtrl = TextEditingController(); // Email 輸入
  final TextEditingController _pwdCtrl = TextEditingController(); // 密碼輸入
  bool _loading = false; // 是否在處理中
  String? _error; // 錯誤訊息

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  /// 格式化錯誤訊息
  String _formatAuthError(Object e) {
    if (e is FirebaseAuthException) {
      return e.message ?? 'Unknown error encountered.';
    }
    var msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring('Exception: '.length);
    }
    // 如需可再加入更多處理（如正則移除 [firebase_auth/...] 標籤）
    return msg;
  }

  /// submit 表單：signUp=true => 註冊，否則登入
  Future<void> _submit({required bool signUp}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (signUp) {
        await AuthService.signUp(
          email: _emailCtrl.text.trim(),
          password: _pwdCtrl.text.trim(),
        );
      } else {
        await AuthService.signIn(
          email: _emailCtrl.text.trim(),
          password: _pwdCtrl.text.trim(),
        );
      }
    } catch (e) {
      setState(() {
        _error = _formatAuthError(e);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Logo
                Image.asset(
                  'assets/image/GeminEye_Logo.png',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 20),

                // Email
                TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    prefixIcon: const Icon(Icons.email, color: Colors.white70),
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                TextField(
                  controller: _pwdCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // 錯誤訊息
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 30),

                // Loading or Buttons
                _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        children: [
                          // Email Login
                          ElevatedButton.icon(
                            onPressed: () => _submit(signUp: false),
                            icon: const Icon(Icons.login, color: Colors.white),
                            label: const Text('Email Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Create Account
                          OutlinedButton.icon(
                            onPressed: () => _submit(signUp: true),
                            icon: const Icon(Icons.person_add,
                                color: Colors.white),
                            label: const Text('Create an Email'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFAC230),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Google Sign-In
                          OutlinedButton.icon(
                            onPressed: () async {
                              setState(() => _error = null);
                              try {
                                await AuthService.signInWithGoogle();
                              } catch (e) {
                                setState(() {
                                  _error = _formatAuthError(e);
                                });
                              }
                            },
                            icon: Image.asset(
                              'assets/image/google_logo.png',
                              height: 24,
                              width: 24,
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
