import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aiworkflowautomation/controller/chat_controller.dart';
import 'package:aiworkflowautomation/model/userModel.dart';

class DeepSeekChatScreen extends StatefulWidget {
  const DeepSeekChatScreen({super.key});

  @override
  State<DeepSeekChatScreen> createState() => _DeepSeekChatScreenState();
}

class _DeepSeekChatScreenState extends State<DeepSeekChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: Consumer<ChatController>(
        builder: (context, chatController, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'DeepSeek AI',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => chatController.clearChat(),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatController.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatController.messages[index];
                      final isUser = message.role == 'user';
                      return _buildMessageBubble(message, isUser);
                    },
                  ),
                ),
                if (chatController.isLoading)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    minHeight: 1,
                  ),
                _buildMessageInput(chatController),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.inter(
              color: isUser
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 15,
            ),
            strong: GoogleFonts.inter(
              color: isUser
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            em: GoogleFonts.inter(
              color: isUser
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatController chatController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !chatController.isLoading,
              decoration: InputDecoration(
                hintText: chatController.isLoading
                    ? 'DeepSeek is thinking...'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty && !chatController.isLoading) {
                  chatController.sendMessage(text);
                  _messageController.clear();
                  _scrollToBottom();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: chatController.isLoading
                ? null
                : () {
                    final text = _messageController.text;
                    if (text.isNotEmpty) {
                      chatController.sendMessage(text);
                      _messageController.clear();
                      _scrollToBottom();
                    }
                  },
            child: CircleAvatar(
              backgroundColor: chatController.isLoading
                  ? Colors.grey.withOpacity(0.3)
                  : Theme.of(context).primaryColor,
              child: chatController.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
