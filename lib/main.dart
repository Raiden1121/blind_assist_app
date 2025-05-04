import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:blind_assist_app/widgets/camera_view.dart';
import 'package:blind_assist_app/widgets/voice_input.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';
import 'package:blind_assist_app/services/mcp_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BlindAssistApp());
}

class BlindAssistApp extends StatelessWidget {
  const BlindAssistApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Assist App',
      home: const AssistHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AssistHomePage extends StatefulWidget {
  const AssistHomePage({Key? key}) : super(key: key);

  @override
  State<AssistHomePage> createState() => _AssistHomePageState();
}

class _AssistHomePageState extends State<AssistHomePage> {
  final SpeechPlayer speechPlayer = SpeechPlayer();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      // ✅ 播放啟動語音
      await speechPlayer.speak("System started. Monitoring the environment.");

      // ✅ 寫入 Firestore
      try {
        await FirebaseFirestore.instance.collection('testCollection').add({
          'timestamp': DateTime.now(),
          'message': 'Hello from Flutter',
        });
        print("✅ Successfully added to Firestore");
      } catch (e) {
        print("🔥 Failed to add to Firestore: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CameraView(),
          Align(
            alignment: Alignment.bottomCenter,
            child: VoiceInput(
              onResult: (String text) async {
                print('🎙 Recognized: $text');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('你說：$text')),
                );
                await MCPService.handleUserCommand(text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
