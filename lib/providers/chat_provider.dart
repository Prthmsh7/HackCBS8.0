import 'package:flutter/foundation.dart';
import '../services/a4f_service.dart';
import '../services/voice_service.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ChatProvider with ChangeNotifier {
  final A4FService _a4fService = A4FService();
  final VoiceService _voiceService = VoiceService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  String _currentStreamingText = '';
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isListening => _isListening;
  String get currentStreamingText => _currentStreamingText;
  String? get error => _error;
  VoiceService get voiceService => _voiceService;

  ChatProvider() {
    _voiceService.stateStream.listen((state) {
      _isListening = state == VoiceState.listening;
      notifyListeners();
    });

    _voiceService.transcriptionStream.listen((transcript) {
      sendMessage(transcript);
    });
  }

  Future<void> initializeVoice() async {
    try {
      await _voiceService.initialize();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize voice: $e';
      notifyListeners();
    }
  }

  Future<void> startListening() async {
    if (_isLoading || _isListening) return;
    
    try {
      await _voiceService.startListening();
      _error = null;
    } catch (e) {
      _error = 'Failed to start listening: $e';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  Future<void> sendMessage(String message, {bool useVoice = false}) async {
    if (message.trim().isEmpty || _isLoading) return;

    // Stop listening if active
    if (_isListening) {
      await stopListening();
    }

    // Add user message
    _messages.add(ChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _currentStreamingText = '';
    _error = null;
    notifyListeners();

    try {
      // Build conversation history
      final conversationHistory = _messages
          .where((m) => !m.isStreaming)
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      // Create streaming message placeholder
      final streamingMessage = ChatMessage(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      _messages.add(streamingMessage);
      notifyListeners();

      // Stream response
      String fullResponse = '';
      await for (final token in _a4fService.streamResponse(
        message,
        conversationHistory: conversationHistory,
      )) {
        fullResponse += token;
        _currentStreamingText = fullResponse;
        
        // Update the streaming message
        final lastIndex = _messages.length - 1;
        if (lastIndex >= 0 && _messages[lastIndex].isStreaming) {
          _messages[lastIndex] = _messages[lastIndex].copyWith(
            content: fullResponse,
          );
        }
        
        notifyListeners();

        // Speak token if voice is enabled
        if (useVoice) {
          // For smoother streaming, we'll speak in sentence chunks
          // This is a simplified approach
          if (token.contains('.') || token.contains('!') || token.contains('?')) {
            await _voiceService.speakStreaming(fullResponse);
          }
        }
      }

      // Finalize the message
      final lastIndex = _messages.length - 1;
      if (lastIndex >= 0) {
        _messages[lastIndex] = _messages[lastIndex].copyWith(
          content: fullResponse,
          isStreaming: false,
        );
      }

      // Speak full response if voice is enabled
      if (useVoice && fullResponse.isNotEmpty) {
        await _voiceService.speak(fullResponse);
      }

      _currentStreamingText = '';
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to get response: $e';
      
      // Remove streaming message on error
      if (_messages.isNotEmpty && _messages.last.isStreaming) {
        _messages.removeLast();
      }
      
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _currentStreamingText = '';
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}

