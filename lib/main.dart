// =======================================================
// main.dart
// 這是 Blind Assist App 的主入口檔案
// 功能：
// 1️⃣ 初始化 Firebase
// 2️⃣ 根據是否登入決定顯示 LoginPage 或 AssistHomePage
// 3️⃣ AssistHomePage：主頁面（包含相機影像、語音輸入、語音播報）
// =======================================================

import 'package:blind_assist_app/widgets/settings_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart'; // ← flutterfire configure 產生的檔案，用於初始化 Firebase
import 'package:blind_assist_app/widgets/camera_view.dart'; // 相機畫面
import 'package:blind_assist_app/widgets/voice_input.dart'; // 語音輸入工具
import 'package:blind_assist_app/widgets/speech_player.dart'; // 語音播放工具
// MCP 後端 API 呼叫
import 'package:blind_assist_app/widgets/login_page.dart'; // 登入／註冊畫面
import 'package:blind_assist_app/grpc/grpc_client.dart';

void main() async {
  // 確保 Flutter 綁定初始化（執行 async 前必需）
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    // 初始化 gRPC 客戶端
    await GrpcClient.init();
    GrpcClient.testGrpc();
    print("✅ gRPC Client initialized");
  } catch (e) {
    print("🔥 gRPC Client initialization failed: $e");
  }

  // 啟動 Flutter 應用
  runApp(const BlindAssistApp());
}

/// Flutter 應用主體
class BlindAssistApp extends StatelessWidget {
  const BlindAssistApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeminEye', // 應用程式標題
      debugShowCheckedModeBanner: false, // 移除 debug 標記
      home: StreamBuilder<User?>(
        // 監聽 Firebase 登入狀態
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 🔄 Firebase 初始化中 → 顯示 loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // ✅ 已登入 → 顯示 AssistHomePage
          if (snapshot.hasData) {
            return const AssistHomePage();
          }
          // ❌ 未登入 → 顯示 LoginPage
          return const LoginPage();
        },
      ),
    );
  }
}

/// 應用的主畫面
class AssistHomePage extends StatefulWidget {
  const AssistHomePage({Key? key}) : super(key: key);

  @override
  State<AssistHomePage> createState() => _AssistHomePageState();
}

class _AssistHomePageState extends State<AssistHomePage> {
  // 建立語音播放工具
  final SpeechPlayer speechPlayer = SpeechPlayer();

  @override
  void initState() {
    super.initState();

    // 初始化後執行
    Future.microtask(() async {
      // 播放啟動語音提示
      await speechPlayer
          .speak("System started. Double tap the screen to open camera.");

      // （示範用）寫入一筆資料到 Firestore
      try {
        await FirebaseFirestore.instance.collection('testCollection').add({
          'timestamp': DateTime.now(),
          'message': 'Hello from Flutter',
        });
        print("✅ Added to Firestore");
      } catch (e) {
        print("🔥 Firestore write failed: $e");
      }
    });
  }

  @override
  void dispose() {
    // 釋放語音播放工具資源
    GrpcClient.shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blind Assist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // Play a sound for blind users to know settings are opened
              speechPlayer.speak("Settings opened");

              // Show settings bottom sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Makes it taller than standard
                backgroundColor: Colors.transparent,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: const SettingsBottomSheet(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 登出 Firebase
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const CameraView(), // 相機畫面
          Align(
            alignment: Alignment.bottomCenter,
            child: const VoiceInput(),
          ),
        ],
      ),
    );
  }
}
