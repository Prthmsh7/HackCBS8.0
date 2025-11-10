import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../controllers/voice_controller.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final VoiceController _voiceController = VoiceController();
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      await _voiceController.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize voice: $e')),
        );
      }
    }
  }

  Future<void> _handleMicPress() async {
    try {
      // Toggle conversation on/off
      await _voiceController.toggleConversation();
      setState(() {}); // Update UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getStatusText() {
    if (!_voiceController.isConversationActive) {
      return 'Tap to start conversation';
    }
    
    switch (_voiceController.state) {
      case VoiceState.idle:
        return 'Conversation active - Tap to stop';
      case VoiceState.listening:
        return 'Listening... (Tap to stop)';
      case VoiceState.processing:
        return 'Processing...';
      case VoiceState.speaking:
        return 'Alfredo is speaking...';
    }
  }

  IconData _getStatusIcon() {
    if (!_voiceController.isConversationActive) {
      return Icons.mic_rounded;
    }
    
    switch (_voiceController.state) {
      case VoiceState.idle:
        return Icons.mic_rounded;
      case VoiceState.listening:
        return Icons.mic_rounded;
      case VoiceState.processing:
        return Icons.hourglass_empty_rounded;
      case VoiceState.speaking:
        return Icons.volume_up_rounded;
    }
  }

  Color _getStatusColor() {
    if (!_voiceController.isConversationActive) {
      return AppTheme.primaryOrange;
    }
    
    switch (_voiceController.state) {
      case VoiceState.idle:
        return Colors.green;
      case VoiceState.listening:
        return Colors.red;
      case VoiceState.processing:
        return Colors.blue;
      case VoiceState.speaking:
        return Colors.green;
    }
  }

  @override
  void dispose() {
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alfredo Voice Chat'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Conversation Display Area
            Expanded(
              child: Center(
                child: _voiceController.lastResponse != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.smart_toy_rounded,
                              size: 64,
                              color: AppTheme.primaryOrange,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.gray100,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Text(
                                _voiceController.lastResponse!,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: AppTheme.gray400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.gray600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the mic to speak',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.gray500,
                                ),
                          ),
                        ],
                      ),
              ),
            ),

            // Status Indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                _getStatusText(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            // Microphone Button
            Padding(
              padding: const EdgeInsets.all(32),
              child: GestureDetector(
                onTap: _handleMicPress,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

