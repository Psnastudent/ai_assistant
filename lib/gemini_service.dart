import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  Future<void> initialize(String apiKey) async {
    if (apiKey.isEmpty) {
      debugPrint('Gemini API key is empty.');
      return;
    }
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      _chatSession = _model!.startChat();
    } catch (e) {
      debugPrint('Failed to initialize Gemini: $e');
    }
  }

  Future<String> sendMessage(String message) async {
    if (_chatSession == null) {
      return "I'm not connected to Gemini yet. Please set your API key in Settings.";
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'Sorry, I have no response.';
    } catch (e) {
      debugPrint('Error from Gemini: $e');
      return "Oops, something went wrong while thinking.";
    }
  }
}
