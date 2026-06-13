import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

// Replace with your actual ElevenLabs API Key and preferred Voice ID
const String elevenLabsApiKey = 'sk_973f55501039964bb0986afbb53fc86fc47d2fdd55f305dc';
const String elevenLabsVoiceId = 'pNInz6obpgDQGcFmaJcg'; // Example: Adam/Rachel

class ElevenLabsService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> speak(String text) async {
    if (elevenLabsApiKey.isEmpty || elevenLabsApiKey == 'YOUR_ELEVENLABS_API_KEY') {
      debugPrint('Please set your ElevenLabs API Key.');
      return;
    }

    final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$elevenLabsVoiceId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': elevenLabsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "text": text,
          "model_id": "eleven_monolingual_v1",
          "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.5
          }
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await _audioPlayer.play(BytesSource(bytes));
      } else {
        debugPrint('Failed to generate speech: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(300, 450),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const AssistantApp());

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(300, 450);
    win.size = const Size(300, 450);
    win.alignment = Alignment.bottomRight;
    win.show();
  });
}

class AssistantApp extends StatelessWidget {
  const AssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const AssistantHome(),
    );
  }
}

class AssistantHome extends StatefulWidget {
  const AssistantHome({super.key});

  @override
  State<AssistantHome> createState() => _AssistantHomeState();
}

class _AssistantHomeState extends State<AssistantHome> {
  final ElevenLabsService _ttsService = ElevenLabsService();
  String _message = "Waiting for notifications...";
  bool _isJumping = false;

  void _simulateNotification() async {
    setState(() {
      _message = "You got a new email!";
      _isJumping = true;
    });

    _ttsService.speak("You got a new email, Santhosh!");

    // Stop jumping animation after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isJumping = false;
        });
      }
    });
    
    // Clear message after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _message = "Waiting for notifications...";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onPanUpdate: (details) {
          appWindow.position += details.delta;
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Message Bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _message,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              
              // Character
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                transform: Matrix4.translationValues(0, _isJumping ? -20 : 0, 0),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 10,
                      )
                    ]
                  ),
                  child: Center(
                    child: Text(
                      _isJumping ? '(^‿^)' : '(◕‿◕)',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Mock Notification Trigger
              ElevatedButton(
                onPressed: _simulateNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Simulate Notification'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
