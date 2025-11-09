import 'package:flutter/foundation.dart';
import '../models/ai_call_state.dart';
import '../services/ai_call_service.dart';
import '../services/camera_service.dart';
import '../services/ml_kit_service.dart';
import 'dart:async';

class AiCallProvider extends ChangeNotifier {
  final AiCallService _aiService = AiCallService();
  final CameraService _cameraService = CameraService();
  final MlKitService _mlKitService = MlKitService();

  AiCallState _state = AiCallState();
  String _alfredoResponse = '';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isStreaming = false;
  String? _lastFramePath;
  Map<String, dynamic>? _lastMlKitData;

  // Getters
  AiCallState get state => _state;
  String get alfredoResponse => _alfredoResponse;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isStreaming => _isStreaming;
  CameraService get cameraService => _cameraService;

  AiCallProvider() {
    // Don't initialize camera in constructor - let the screen handle it
    _initializeMlKit();
  }

  Future<void> _initializeMlKit() async {
    await _mlKitService.initialize();
  }

  Future<bool> initializeCamera() async {
    if (_cameraService.isInitialized) {
      return true;
    }
    
    final cameraInitialized = await _cameraService.initialize();
    
    // Notify listeners when camera is ready
    if (cameraInitialized) {
      // Add a small delay to ensure controller is fully ready
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();
    }
    
    return cameraInitialized;
  }

  /// Process user utterance
  Future<void> processUserUtterance(String utterance) async {
    if (_isProcessing) {
      print('⚠️ [PROVIDER] Already processing, ignoring utterance');
      return;
    }

    print('🎤 [PROVIDER] Processing user utterance: "$utterance"');
    _isProcessing = true;
    notifyListeners();

    try {
      // Automatically capture a fresh frame when user speaks
      if (_cameraService.isInitialized) {
        print('📸 [PROVIDER] Capturing fresh frame for user utterance...');
        await _captureAndProcessFrame(null);
      }
      
      // Get latest frame and ML Kit data
      final framePath = _lastFramePath;
      final mlKitData = _lastMlKitData;
      
      print('📸 [PROVIDER] Frame path: ${framePath ?? "none"}');
      print('🔍 [PROVIDER] ML Kit data: ${mlKitData != null ? "available" : "none"}');

      // Call AI service
      print('🤖 [PROVIDER] Calling AI service...');
      final response = await _aiService.processUserInput(
        utterance: utterance,
        frameImagePath: framePath,
        mlKitData: mlKitData,
        currentState: _state,
      );

      print('🤖 [PROVIDER] AI response received: ${response.text}');
      print('🛠️ [PROVIDER] Tool calls: ${response.toolCalls?.length ?? 0}');

      // Update response text
      _alfredoResponse = response.text;

      // Execute tool calls if any
      if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
        print('🔄 [PROVIDER] Executing ${response.toolCalls!.length} tool calls');
        for (final toolCall in response.toolCalls!) {
          print('🔄 [PROVIDER] Processing tool call: ${toolCall.name}');
          await _executeToolCall(toolCall);
        }
      } else {
        print('ℹ️ [PROVIDER] No tool calls in response');
      }

      // Update state if provided
      if (response.state != null) {
        _state = response.state!;
      }

      notifyListeners();
    } catch (e) {
      _alfredoResponse = "I encountered an error: $e";
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Execute a tool call
  Future<void> _executeToolCall(ToolCall toolCall) async {
    final result = await _aiService.executeToolCall(toolCall);

    switch (toolCall.name) {
      case 'start_frame_stream':
        if (result['success'] == true) {
          final interval = toolCall.args['interval_sec'] as int? ?? 5;
          _startFrameStream(interval);
        }
        break;

      case 'stop_frame_stream':
        if (result['success'] == true) {
          _stopFrameStream();
        }
        break;

      case 'request_frame':
        await _captureAndProcessFrame(toolCall.args['note'] as String?);
        break;

      case 'set_timer':
        if (result['success'] == true && result['timer'] != null) {
          final timerData = result['timer'] as Map<String, dynamic>;
          _addTimer(TimerInfo.fromJson(timerData));
        }
        break;

      case 'advance_step':
        if (result['success'] == true) {
          final delta = result['step_delta'] as int? ?? 1;
          _advanceStep(delta);
        }
        break;

      case 'generate_recipe':
        if (result['success'] == true && result['recipe'] != null) {
          final recipeData = result['recipe'] as Map<String, dynamic>;
          _updateRecipe(RecipeInfo.fromJson(recipeData));
        }
        break;

      case 'read_pantry':
        // Pantry data is read and available to AI, no UI update needed
        break;

      case 'add_pantry_item':
        print('📦 [PROVIDER] add_pantry_item result: $result');
        if (result['success'] == true) {
          _state = _state.copyWith(
            notes: result['message'] as String? ?? 'Pantry item added',
          );
          print('✅ [PROVIDER] Pantry item added successfully');
        } else {
          print('❌ [PROVIDER] Failed to add pantry item: ${result['error']}');
        }
        notifyListeners();
        break;

      case 'update_pantry_item':
        print('📦 [PROVIDER] update_pantry_item result: $result');
        if (result['success'] == true) {
          _state = _state.copyWith(
            notes: result['message'] as String? ?? 'Pantry item updated',
          );
          print('✅ [PROVIDER] Pantry item updated successfully');
        } else {
          print('❌ [PROVIDER] Failed to update pantry item: ${result['error']}');
        }
        notifyListeners();
        break;

      case 'remove_pantry_item':
        print('📦 [PROVIDER] remove_pantry_item result: $result');
        if (result['success'] == true) {
          _state = _state.copyWith(
            notes: result['message'] as String? ?? 'Pantry item removed',
          );
          print('✅ [PROVIDER] Pantry item removed successfully');
        } else {
          print('❌ [PROVIDER] Failed to remove pantry item: ${result['error']}');
        }
        notifyListeners();
        break;

      case 'add_to_shopping_list':
        // Shopping list updated, notify listeners
        notifyListeners();
        break;

      case 'nutrition_estimate':
        // Nutrition data available to AI, no UI update needed
        break;

      case 'log_meal':
        // Meal logged, notify listeners
        notifyListeners();
        break;

      case 'summarize_photo':
        // Photo summarized, no UI update needed
        break;
    }
  }

  void _startFrameStream(int intervalSeconds) {
    if (_isStreaming) return;
    if (!_cameraService.isInitialized) {
      // Try to initialize if not already done
      _cameraService.initialize().then((initialized) {
        if (initialized) {
          _cameraService.startFrameStream(intervalSeconds, (imagePath) async {
            await _processFrame(imagePath);
          });
          _isStreaming = true;
          _state = _state.copyWith(notes: 'Streaming frames');
          notifyListeners();
        }
      });
      return;
    }

    _cameraService.startFrameStream(intervalSeconds, (imagePath) async {
      await _processFrame(imagePath);
    });

    _isStreaming = true;
    _state = _state.copyWith(notes: 'Streaming frames');
    notifyListeners();
  }

  void _stopFrameStream() {
    _cameraService.stopFrameStream();
    _isStreaming = false;
    _state = _state.copyWith(notes: 'Streaming paused');
    notifyListeners();
  }

  Future<void> _captureAndProcessFrame(String? note) async {
    final framePath = await _cameraService.captureFrame();
    if (framePath != null) {
      await _processFrame(framePath);
    }
  }

  Future<void> _processFrame(String imagePath) async {
    print('📸 [PROVIDER] Processing frame: $imagePath');
    _lastFramePath = imagePath;

    // Run ML Kit detection on the captured frame
    try {
      print('🔍 [PROVIDER] Running ML Kit detection...');
      final mlKitResult = await _mlKitService.detectObjects(imagePath);
      _lastMlKitData = mlKitResult.toJson();
      print('✅ [PROVIDER] ML Kit detection complete');
      print('📦 [PROVIDER] Detected objects: ${mlKitResult.objects}');
      print('⚠️ [PROVIDER] Detected hazards: ${mlKitResult.hazards}');
      print('📝 [PROVIDER] Notes: ${mlKitResult.notes}');
      
      if (mlKitResult.objects.isEmpty && mlKitResult.hazards.isEmpty) {
        print('⚠️ [PROVIDER] No objects detected - image might be blurry or ML Kit not working');
      }
    } catch (e, stackTrace) {
      print('❌ [PROVIDER] ML Kit detection failed: $e');
      print('❌ [PROVIDER] Stack trace: $stackTrace');
      // If ML Kit fails, still store the frame path for AI
      _lastMlKitData = {
        'error': e.toString(),
        'objects': [],
        'hazards': [],
        'notes': 'ML Kit detection failed: $e'
      };
    }

    notifyListeners();
  }

  void _addTimer(TimerInfo timer) {
    final timers = List<TimerInfo>.from(_state.timers)..add(timer);
    _state = _state.copyWith(timers: timers);
    notifyListeners();
  }

  void _advanceStep(int delta) {
    final newStepIndex = (_state.stepIndex + delta).clamp(0, _state.totalSteps);
    _state = _state.copyWith(stepIndex: newStepIndex);
    notifyListeners();
  }

  void _updateRecipe(RecipeInfo recipe) {
    _state = _state.copyWith(recipe: recipe);
    notifyListeners();
  }

  void setListening(bool listening) {
    _isListening = listening;
    notifyListeners();
  }

  void clearResponse() {
    _alfredoResponse = '';
    notifyListeners();
  }

  @override
  void dispose() {
    // Don't dispose camera service here - let it persist across navigation
    // Only dispose when app is closing or provider is truly being disposed
    // _cameraService.dispose();
    _mlKitService.dispose();
    super.dispose();
  }
  
  // Method to dispose camera when needed (e.g., when app is closing)
  void disposeCamera() {
    _cameraService.dispose();
  }
}




