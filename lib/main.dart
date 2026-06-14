import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:async';
import 'package:screen_retriever/screen_retriever.dart';
import 'state_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'settings_service.dart';
import 'gemini_service.dart';

class ElevenLabsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SettingsService _settingsService = SettingsService();

  Future<void> speak(String text) async {
    final apiKey = await _settingsService.getElevenLabsKey();
    final voiceId = await _settingsService.getElevenLabsVoiceId();

    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_ELEVENLABS_API_KEY') {
      debugPrint('Please set your ElevenLabs API Key.');
      return;
    }

    final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': apiKey,
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
    size: Size(350, 500),
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

  doWhenWindowReady(() async {
    final win = appWindow;
    win.minSize = const Size(350, 500);
    win.size = const Size(350, 500);
    
    // Accurately position window right above the taskbar
    Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    double right = primaryDisplay.visiblePosition!.dx + primaryDisplay.visibleSize!.width;
    double bottom = primaryDisplay.visiblePosition!.dy + primaryDisplay.visibleSize!.height;
    win.position = Offset(right - 350, bottom - 500);
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



class _AssistantHomeState extends State<AssistantHome> with SingleTickerProviderStateMixin {
  final ElevenLabsService _ttsService = ElevenLabsService();
  final GeminiService _geminiService = GeminiService();
  final SettingsService _settingsService = SettingsService();

  String _message = "Waiting for notifications...";
  bool _showChatInput = false;
  bool _isExpanded = false;
  
  AssistantState _currentState = AssistantState.idle;

  final TextEditingController _chatController = TextEditingController();

  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;
  
  Timer? _cursorTimer;
  Offset _cursorPos = Offset.zero;
  Offset _windowCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initGemini();
    
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    
    _startCursorTracking();
  }

  void _startCursorTracking() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) async {
      Offset pos = await screenRetriever.getCursorScreenPoint();
      Rect windowRect = await windowManager.getBounds();
      
      Offset center = Offset(
        windowRect.left + (windowRect.width / 2),
        windowRect.top + (windowRect.height / 2),
      );

      if (mounted && (_cursorPos != pos || _windowCenter != center)) {
        setState(() {
          _cursorPos = pos;
          _windowCenter = center;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _breatheController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _initGemini() async {
    final key = await _settingsService.getGeminiKey();
    if (key != null && key.isNotEmpty) {
      await _geminiService.initialize(key);
    }
  }

  void _openSettings() {
    final geminiController = TextEditingController();
    final elevenLabsController = TextEditingController();
    final voiceIdController = TextEditingController();

    _settingsService.getGeminiKey().then((val) => geminiController.text = val ?? '');
    _settingsService.getElevenLabsKey().then((val) => elevenLabsController.text = val ?? '');
    _settingsService.getElevenLabsVoiceId().then((val) => voiceIdController.text = val ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: geminiController,
                  decoration: const InputDecoration(labelText: "Gemini API Key"),
                ),
                TextField(
                  controller: elevenLabsController,
                  decoration: const InputDecoration(labelText: "ElevenLabs API Key"),
                ),
                TextField(
                  controller: voiceIdController,
                  decoration: const InputDecoration(labelText: "Voice ID"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _settingsService.saveGeminiKey(geminiController.text);
                await _settingsService.saveElevenLabsKey(elevenLabsController.text);
                await _settingsService.saveElevenLabsVoiceId(voiceIdController.text);
                await _initGemini(); // re-init
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved!')),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();
    setState(() {
      _showChatInput = false;
      _message = "Thinking...";
      _currentState = AssistantState.thinking;
    });

    final response = await _geminiService.sendMessage(text);

    setState(() {
      _message = response;
      _currentState = AssistantState.speaking;
    });

    _ttsService.speak(response);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentState = AssistantState.idle;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate 3D Parallax Tilt based on cursor
    double deltaX = _cursorPos.dx - _windowCenter.dx;
    double deltaY = _cursorPos.dy - _windowCenter.dy;
    
    // Normalize and clamp
    double maxTilt = 0.5; // radians
    double tiltX = (deltaY / 1000).clamp(-maxTilt, maxTilt);
    double tiltY = (-deltaX / 1000).clamp(-maxTilt, maxTilt);

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
              if (_message.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withAlpha(100)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 10,
                      )
                    ]
                  ),
                  child: Text(
                    _message,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Character (Minion Placeholder)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    if (!_isExpanded) _showChatInput = false;
                  });
                },
                child: ScaleTransition(
                  scale: _breatheAnimation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    // Small jump when speaking, slight float when thinking
                    transform: Matrix4.translationValues(
                      0, 
                      _currentState == AssistantState.speaking ? -15 : (_currentState == AssistantState.thinking ? -5 : 0), 
                      0
                    ),
                    child: Transform(
                      alignment: FractionalOffset.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..rotateX(tiltX)
                        ..rotateY(tiltY),
                      child: SizedBox(
                        width: 120,
                        height: 140,
                        child: Image.asset(
                          'assets/minion.gif',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 80, color: Colors.yellow);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Action Buttons
              if (_isExpanded)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Chat Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showChatInput = !_showChatInput;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 5)
                          ],
                        ),
                        child: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Settings Button
                    GestureDetector(
                      onTap: _openSettings,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 5)
                          ],
                        ),
                        child: const Icon(Icons.settings_outlined, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              
              // Chat Input Field
              if (_isExpanded && _showChatInput) ...[
                const SizedBox(height: 15),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 5)
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            hintText: 'Talk to Gemini...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blueAccent),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
