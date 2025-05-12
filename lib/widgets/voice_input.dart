import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // 錄音工具
import 'package:permission_handler/permission_handler.dart'; // 權限處理
import 'package:http/http.dart' as http; // 傳送 HTTP 請求
import 'package:http_parser/http_parser.dart'; // 指定 Content-Type
import 'dart:typed_data'; // 用於記憶體資料 Uint8List
import 'dart:async'; // 用於 StreamController 與 Subscription

class VoiceInput extends StatefulWidget {
  const VoiceInput({super.key});

  @override
  State<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends State<VoiceInput> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder(); // 錄音器實例
  bool _isRecording = false; // 是否正在錄音
  final List<int> _rawDataBuffer = []; // 用來存放錄下來的 PCM 原始資料（記憶體）

  StreamController<Uint8List>? _audioStreamController; // 音訊資料的 StreamController
  StreamSubscription<Uint8List>? _recorderSubscription; // 音訊資料的訂閱者

  @override
  void initState() {
    super.initState();
    _initRecorder(); // 初始化錄音器與權限
  }

  /// 初始化錄音器與麥克風權限
  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request(); // 請求麥克風權限
    if (status.isGranted) {
      await _recorder.openRecorder(); // 啟動錄音器
    } else {
      // 權限被拒，提示用戶
      print('❗麥克風權限被拒絕');
    }
  }

  /// 開始錄音，使用 Codec.pcm16（16-bit RAW PCM）
  Future<void> _startRecording() async {
    _rawDataBuffer.clear(); // 清空舊的資料

    // 建立 StreamController 以接收錄音資料
    _audioStreamController = StreamController<Uint8List>();

    // 監聽音訊串流資料，每當收到一段 PCM 音訊就加入 buffer
    _recorderSubscription = _audioStreamController!.stream.listen((chunk) {
      _rawDataBuffer.addAll(chunk); // 將 Uint8List 資料加到原始緩衝區
    });

    // 啟動錄音，將資料傳入 StreamSink
    await _recorder.startRecorder(
      codec: Codec.pcm16, // RAW PCM（16-bit, little-endian）
      sampleRate: 16000, // 錄音取樣率
      numChannels: 1, // 單聲道
      toStream: _audioStreamController!.sink, // ✅ 正確提供 StreamSink
    );

    setState(() => _isRecording = true); // 更新 UI 狀態
  }

  /// 停止錄音並上傳記憶體中的資料
  Future<void> _stopRecording() async {
    await _recorder.stopRecorder(); // 停止錄音
    await _recorderSubscription?.cancel(); // 停止接收資料
    _recorderSubscription = null;
    await _audioStreamController?.close(); // 關閉 Stream
    _audioStreamController = null;

    setState(() => _isRecording = false); // 更新 UI 狀態

    // 將 List<int> 轉成 Uint8List（可傳輸）
    Uint8List rawBytes = Uint8List.fromList(_rawDataBuffer);

    // 上傳音訊資料至後端
    await uploadRawPcmAudio(rawBytes);
  }

  /// 將錄音資料（記憶體中的 raw PCM）上傳至後端 API
  Future<void> uploadRawPcmAudio(Uint8List audioBytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://your-api.com/upload'), // ← 改成你的 API URL
    );

    request.files.add(http.MultipartFile.fromBytes(
      'file', // 對應後端的欄位名稱
      audioBytes,
      filename: 'recording.pcm', // 任意檔名
      contentType: MediaType('audio', 'L16'), // RAW PCM 格式的 Content-Type
    ));

    final response = await request.send();
    print(response.statusCode == 200 ? '✅ 上傳成功' : '❌ 上傳失敗');
  }

  @override
  void dispose() {
    _recorder.closeRecorder(); // 關閉錄音器資源
    super.dispose();
  }

  /// 錄音按鈕（長按錄音）
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _startRecording(), // 手指按下 → 開始錄音
      onPointerUp: (_) => _stopRecording(), // 放開手指 → 停止錄音
      child: FloatingActionButton(
        backgroundColor: _isRecording
            ? const Color.fromARGB(255, 219, 54, 54) // 錄音中：紅色
            : const Color.fromARGB(255, 113, 52, 52), // 待命：深紅
        onPressed: () {}, // 不使用 onPressed，改用 Listener 控制
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none, // 顯示不同圖示
          size: 60,
        ),
      ),
    );
  }
}
