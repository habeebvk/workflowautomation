import 'package:flutter/material.dart';
import 'package:aiworkflowautomation/model/userModel.dart';
import 'package:aiworkflowautomation/service/deepseek_service.dart';

class ChatController extends ChangeNotifier {
  final DeepSeekChatService _chatService = DeepSeekChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(role: 'user', content: text));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(_messages);
      // Add assistant response
      _messages.add(ChatMessage(role: 'assistant', content: response));
    } catch (e) {
      _messages.add(
        ChatMessage(role: 'assistant', content: 'Error: ${e.toString()}'),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
