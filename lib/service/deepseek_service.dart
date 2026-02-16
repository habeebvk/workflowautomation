import 'dart:convert';
import 'package:aiworkflowautomation/config/deepseek.dart';
import 'package:aiworkflowautomation/model/userModel.dart';
import 'package:http/http.dart' as http;

class DeepSeekChatService {
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final response = await http.post(
      Uri.parse(DeepSeekConfig.baseUrl),
      headers: {
        ...DeepSeekConfig.headers,
        "Authorization": "Bearer ${DeepSeekConfig.apiKey}",
      },
      body: jsonEncode({
        "model": "openrouter/free",
        "messages": messages.map((m) => m.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("DeepSeek API error: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return data["choices"][0]["message"]["content"];
  }
}
