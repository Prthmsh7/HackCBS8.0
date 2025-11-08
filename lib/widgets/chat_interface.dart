import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';

class ChatInterface extends StatefulWidget {
  final bool isFullScreen;
  
  const ChatInterface({
    super.key,
    this.isFullScreen = false,
  });

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

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
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Auto-scroll when new messages arrive
        if (chatProvider.messages.isNotEmpty) {
          _scrollToBottom();
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: widget.isFullScreen
                ? BorderRadius.zero
                : BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Chat Header
              if (widget.isFullScreen)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.gray200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.smart_toy_rounded,
                        color: AppTheme.primaryOrange,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Alfredo AI Assistant',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

              // Messages List
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: AppTheme.gray400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation with Alfredo',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.gray600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the mic to speak or type a message',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.gray500,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          return _buildMessageBubble(message, chatProvider);
                        },
                      ),
              ),

              // Error Display
              if (chatProvider.error != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chatProvider.error!,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Input Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Text Input
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppTheme.gray100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            chatProvider.sendMessage(text.trim());
                            _textController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Voice Button
                    _buildVoiceButton(chatProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ChatProvider chatProvider) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryOrange
                    : AppTheme.gray100,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUser ? Colors.white : AppTheme.gray900,
                        ),
                  ),
                  if (message.isStreaming)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: AppTheme.primaryOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceButton(ChatProvider chatProvider) {
    final isListening = chatProvider.isListening;
    final isLoading = chatProvider.isLoading;

    return GestureDetector(
      onTap: () async {
        if (isListening) {
          await chatProvider.stopListening();
        } else if (!isLoading) {
          await chatProvider.startListening();
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isListening
              ? Colors.red
              : isLoading
                  ? AppTheme.gray400
                  : AppTheme.primaryOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isListening ? Colors.red : AppTheme.primaryOrange)
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isLoading
              ? Icons.hourglass_empty_rounded
              : isListening
                  ? Icons.mic_rounded
                  : Icons.mic_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

