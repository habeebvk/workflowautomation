import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekConfig {
  static const String baseUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String model = "deepseek/deepseek-chat";

  static String get apiKey =>
      (dotenv.env['openrouterkey'] ?? "").replaceAll('"', '').trim();

  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "HTTP-Referer": "https://aiworkflowautomation.com",
    "X-Title": "AI Workflow Automation",
  };
}
