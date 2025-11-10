import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
}

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  VoiceState _state = VoiceState.idle;
  
  final StreamController<VoiceState> _stateController = StreamController<VoiceState>.broadcast();
  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  
  Stream<VoiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  
  VoiceState get currentState => _state;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  VoiceService() {
    _initializeTTS();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final available = await _speech.initialize(
        onError: (error) {
          _updateState(VoiceState.idle);
          _transcriptionController.addError(error.errorMsg);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_isListening) {
              stopListening();
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
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _updateState(VoiceState.idle);
    });
    
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _updateState(VoiceState.idle);
    });
  }

  void _updateState(VoiceState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isListening || _isSpeaking) return;
    
    try {
      _isListening = true;
      _updateState(VoiceState.listening);
      
        await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final transcript = result.recognizedWords.trim();
            if (transcript.isNotEmpty) {
              _transcriptionController.add(transcript);
              stopListening();
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        listenOptions: stt.SpeechListenOptions(cancelOnError: true),
      );
    } catch (e) {
      _isListening = false;
      _updateState(VoiceState.idle);
      _transcriptionController.addError(e);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speech.stop();
      _isListening = false;
      _updateState(VoiceState.idle);
    } catch (e) {
      _isListening = false;
      _updateState(VoiceState.idle);
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      _isSpeaking = true;
      _updateState(VoiceState.speaking);
      
      // Stop any ongoing speech
      await _tts.stop();
      
      // Speak the text
      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      _updateState(VoiceState.idle);
    }
  }

  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;
    
    try {
      await _tts.stop();
      _isSpeaking = false;
      _updateState(VoiceState.idle);
    } catch (e) {
      _isSpeaking = false;
      _updateState(VoiceState.idle);
    }
  }

  Future<void> speakStreaming(String partialText) async {
    if (partialText.trim().isEmpty) return;
    
    // For streaming, we accumulate text and speak in chunks
    // This is a simplified version - you might want to implement
    // a more sophisticated queue system for smoother streaming
    if (!_isSpeaking) {
      await speak(partialText);
    }
  }

  void dispose() {
    _speech.cancel();
    _tts.stop();
    _stateController.close();
    _transcriptionController.close();
  }
}

