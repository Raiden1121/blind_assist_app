// =======================================================
// login_page.dart
// 此檔案實作「登入／註冊畫面」
// ✅ 功能：
// 1️⃣ 使用 Email / 密碼登入 Firebase
// 2️⃣ 使用 Email / 密碼註冊新帳號
// 3️⃣ 顯示登入／註冊過程的錯誤與 loading 狀態
// =======================================================

import 'package:flutter/material.dart';
import 'package:blind_assist_app/services/auth_service.dart'; // 認證服務（自定義 AuthService）

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController(); // Email 輸入控制器
  final _pwdCtrl = TextEditingController(); // 密碼輸入控制器
  bool _loading = false; // 是否正在處理（登入／註冊中）
  String? _error; // 儲存錯誤訊息

  /// 提交表單
  /// [signUp]：若為 true 則執行註冊，否則執行登入
  Future<void> _submit({required bool signUp}) async {
    setState(() {
      _loading = true; // 顯示 loading spinner
      _error = null; // 清空之前的錯誤
    });
    try {
      if (signUp) {
        // ✅ 註冊帳號
        await AuthService.signUp(
          email: _emailCtrl.text.trim(),
          password: _pwdCtrl.text.trim(),
        );
      } else {
        // ✅ 登入帳號
        await AuthService.signIn(
          email: _emailCtrl.text.trim(),
          password: _pwdCtrl.text.trim(),
        );
      }
    } catch (e) {
      // 捕捉錯誤 → 顯示錯誤訊息
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false); // 處理完畢
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87, // ✅ 整體背景：深色
      appBar: AppBar(
        title: const Text('盲人輔助系統登入'), // App 標題
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 頭像圖示
                Icon(Icons.person, size: 80, color: Colors.white70),
                const SizedBox(height: 20),
                // Email 輸入框
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
                // 密碼輸入框
                TextField(
                  controller: _pwdCtrl,
                  obscureText: true, // 密碼隱藏
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    labelText: 'password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  // 錯誤訊息
                  Text(
                    _error!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 30),
                // 若正在處理 → 顯示 loading spinner
                _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _submit(signUp: false),
                            icon: const Icon(Icons.login),
                            label: const Text('Email Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _submit(signUp: true),
                            icon: const Icon(Icons.person_add,
                                color: Colors.white),
                            label: const Text('Create an Email'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70),
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // ← 新增分隔
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await AuthService.signInWithGoogle();
                              } catch (e) {
                                setState(() => _error = e.toString());
                              }
                            },
                            icon: Image.asset(
                              'assets/image/google_logo.png', // 這裡放 Google logo 圖檔路徑
                              height: 24,
                              width: 24,
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white, // 白底
                              side:
                                  const BorderSide(color: Colors.grey), // 灰色邊框
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
