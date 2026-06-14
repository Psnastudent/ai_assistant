import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _geminiKey = 'gemini_api_key';
  static const String _elevenLabsKey = 'elevenlabs_api_key';
  static const String _elevenLabsVoiceKey = 'elevenlabs_voice_id';

  Future<void> saveGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, key);
  }

  Future<String?> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKey);
  }

  Future<void> saveElevenLabsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_elevenLabsKey, key);
  }

  Future<String?> getElevenLabsKey() async {
    final prefs = await SharedPreferences.getInstance();
    // Return hardcoded default if nothing is saved yet
    return prefs.getString(_elevenLabsKey) ?? 'sk_973f55501039964bb0986afbb53fc86fc47d2fdd55f305dc';
  }

  Future<void> saveElevenLabsVoiceId(String voiceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_elevenLabsVoiceKey, voiceId);
  }

  Future<String?> getElevenLabsVoiceId() async {
    final prefs = await SharedPreferences.getInstance();
    // Return hardcoded default if nothing is saved yet
    return prefs.getString(_elevenLabsVoiceKey) ?? 'pNInz6obpgDQGcFmaJcg';
  }
}
