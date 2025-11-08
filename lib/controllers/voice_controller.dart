import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/a4f_service.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
}

class VoiceController {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final A4FService _a4fService = A4FService();
  
  bool _isInitialized = false;
  bool _isConversationActive = false; // Toggle state
  VoiceState _state = VoiceState.idle;
  String? _lastResponse;
  final List<Map<String, String>> _conversationHistory = [];
  
  VoiceState get state => _state;
  bool get isListening => _state == VoiceState.listening;
  bool get isProcessing => _state == VoiceState.processing;
  bool get isSpeaking => _state == VoiceState.speaking;
  bool get isConversationActive => _isConversationActive;
  String? get lastResponse => _lastResponse;

  VoiceController() {
    _initializeTTS();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final available = await _speech.initialize(
        onError: (error) {
          _updateState(VoiceState.idle);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_state == VoiceState.listening) {
              _updateState(VoiceState.idle);
            }
          }
        },
      );
      
      _isInitialized = available;
      
      if (!available) {
        throw Exception('Speech recognition not available');
      }
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> _initializeTTS() async {
    await _tts.setLanguage('en-US');
    // More natural human-like speech settings
    await _tts.setSpeechRate(0.45); // Slightly slower for more natural pace
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0); // Natural pitch
    
    // Use a more natural voice if available
    final voices = await _tts.getVoices;
    if (voices != null && voices.isNotEmpty) {
      // Try to find a more natural-sounding voice
      final naturalVoice = voices.firstWhere(
        (voice) => voice['name']?.toString().toLowerCase().contains('enhanced') == true ||
                   voice['name']?.toString().toLowerCase().contains('premium') == true ||
                   voice['name']?.toString().toLowerCase().contains('neural') == true,
        orElse: () => voices.first,
      );
      
      if (naturalVoice['name'] != null) {
        await _tts.setVoice({'name': naturalVoice['name'], 'locale': naturalVoice['locale']});
      }
    }
    
    _tts.setCompletionHandler(() {
      // When TTS completes, if conversation is active, the loop will continue
      // The loop will handle transitioning back to listening state
      if (_isConversationActive) {
        // Don't set to idle here - let the loop handle it
        // This allows the loop to continue seamlessly
      } else {
        _updateState(VoiceState.idle);
      }
    });
    
    _tts.setErrorHandler((msg) {
      _updateState(VoiceState.idle);
    });
  }

  void _updateState(VoiceState newState) {
    _state = newState;
  }

  /// Toggle conversation on/off
  Future<void> toggleConversation() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isConversationActive) {
      // Stop conversation
      _isConversationActive = false;
      await _speech.stop();
      await _tts.stop();
      _updateState(VoiceState.idle);
    } else {
      // Start continuous conversation
      _isConversationActive = true;
      _conversationHistory.clear(); // Reset history for new conversation
      _startConversationLoop();
    }
  }

  /// Continuous conversation loop
  Future<void> _startConversationLoop() async {
    while (_isConversationActive) {
      try {
        // Step 1: Listen to user input
        _updateState(VoiceState.listening);
        
        String? transcript;
        String? lastPartialResult;
        bool gotFinalResult = false;
        DateTime lastSpeechTime = DateTime.now();
        
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              transcript = result.recognizedWords.trim();
              gotFinalResult = true;
            } else {
              // Track partial results
              lastPartialResult = result.recognizedWords.trim();
              lastSpeechTime = DateTime.now();
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3), // Wait 3 seconds of silence before finalizing
          partialResults: true,
          localeId: 'en_US',
          listenOptions: stt.SpeechListenOptions(cancelOnError: true),
        );
        
        // Wait for final result or timeout
        // Check periodically if we got a final result or if there's been silence
        int attempts = 0;
        while (!gotFinalResult && _isConversationActive && attempts < 150) {
          await Future.delayed(const Duration(milliseconds: 200));
          attempts++;
          
          // If we have partial results but no final result after pause time, use partial
          if (lastPartialResult != null && 
              lastPartialResult!.isNotEmpty &&
              DateTime.now().difference(lastSpeechTime).inSeconds >= 3) {
            transcript = lastPartialResult;
            gotFinalResult = true;
            break;
          }
        }
        
        // Check if conversation was stopped
        if (!_isConversationActive) {
          break;
        }
        
        await _speech.stop();
        
        // Use partial result if we didn't get a final result
        if (transcript == null && lastPartialResult != null && lastPartialResult!.isNotEmpty) {
          transcript = lastPartialResult;
        }
        
        if (transcript == null || transcript!.isEmpty) {
          // No speech detected, continue listening
          continue;
        }
        
        // Step 2: Process with AI (with conversation history)
        _updateState(VoiceState.processing);
        
        final response = await _a4fService.sendMessage(
          transcript!,
          conversationHistory: _conversationHistory,
        );
        _lastResponse = response;
        
        // Add to conversation history
        _conversationHistory.add({'role': 'user', 'content': transcript!});
        _conversationHistory.add({'role': 'assistant', 'content': response});
        
        // Step 3: Speak the response with natural pauses
        _updateState(VoiceState.speaking);
        
        // Add natural pauses for better human-like speech
        final processedResponse = _addNaturalPauses(response);
        
        // Use a completer to wait for TTS to finish
        final completer = Completer<void>();
        bool ttsCompleted = false;
        
        // Set a one-time completion handler for this speak call
        void completionHandler() {
          if (!ttsCompleted && !completer.isCompleted) {
            ttsCompleted = true;
            completer.complete();
          }
        }
        
        _tts.setCompletionHandler(completionHandler);
        await _tts.speak(processedResponse);
        
        // Wait for TTS to complete (with timeout)
        try {
          await completer.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              // TTS timeout - continue anyway
            },
          );
        } catch (e) {
          // Continue even if there's an error
        }
        
        // Reset completion handler
        _tts.setCompletionHandler(() {
          if (_isConversationActive) {
            // Loop will handle state
          } else {
            _updateState(VoiceState.idle);
          }
        });
        
        // Check if conversation is still active before continuing
        if (!_isConversationActive) {
          break;
        }
        
        // Small delay before listening again for natural conversation flow
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        if (_isConversationActive) {
          // If error but conversation is still active, wait a bit and retry
          _updateState(VoiceState.idle);
          await Future.delayed(const Duration(seconds: 1));
          continue;
        } else {
          break;
        }
      }
    }
    
    // Conversation ended
    _updateState(VoiceState.idle);
  }

  Future<void> stopListening() async {
    if (_state == VoiceState.listening) {
      await _speech.stop();
      if (!_isConversationActive) {
        _updateState(VoiceState.idle);
      }
    }
  }

  Future<void> stopSpeaking() async {
    if (_state == VoiceState.speaking) {
      await _tts.stop();
      if (!_isConversationActive) {
        _updateState(VoiceState.idle);
      }
    }
  }

  /// Add natural pauses to make speech more human-like
  String _addNaturalPauses(String text) {
    // Add pauses after sentences
    text = text.replaceAllMapped(
      RegExp(r'([.!?])\s+'),
      (match) => '${match.group(1)}... ',
    );
    
    // Add slight pauses after commas
    text = text.replaceAll(', ', ', ... ');
    
    return text;
  }

  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}

