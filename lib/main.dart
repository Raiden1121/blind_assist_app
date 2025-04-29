import 'package:flutter/material.dart';
import 'package:blind_assist_app/widgets/camera_view.dart';
import 'package:blind_assist_app/widgets/voice_input.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';
import 'package:blind_assist_app/services/mcp_service.dart';

void main() {
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
      speechPlayer.speak("System started. Monitoring the environment.");
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
                print('🎙 Recognized: $text'); // 1) 在 debug console 打出來
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('你說：$text'))); // 2) 在畫面下緣顯示
                await MCPService.handleUserCommand(text); // 原本要呼叫的後端
              },
            ),
          ),
        ],
      ),
    );
  }
}
