import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_button.dart';
import '../providers/ai_call_provider.dart';
import '../models/ai_call_state.dart';

class AiCallScreen extends StatefulWidget {
  const AiCallScreen({super.key});

  @override
  State<AiCallScreen> createState() => _AiCallScreenState();
}

class _AiCallScreenState extends State<AiCallScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  String _transcript = '';

  bool _cameraListenerAdded = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTts();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    final provider = Provider.of<AiCallProvider>(context, listen: false);

    // Initialize camera through provider
    if (!provider.cameraService.isInitialized) {
      print('📷 [SCREEN] Initializing camera...');
      final initialized = await provider.initializeCamera();
      if (initialized && mounted) {
        print('✅ [SCREEN] Camera initialized, setting up listener...');
        _setupCameraListener(provider);
        if (mounted) {
          setState(() {});
        }
      } else {
        print('❌ [SCREEN] Camera initialization failed');
      }
    } else {
      // Camera already initialized, just setup listener
      print('✅ [SCREEN] Camera already initialized, setting up listener...');
      _setupCameraListener(provider);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _setupCameraListener(AiCallProvider provider) {
    if (_cameraListenerAdded) return;

    final controller = provider.cameraService.controller;
    if (controller != null && mounted) {
      controller.addListener(_onCameraControllerChanged);
      _cameraListenerAdded = true;
    }
  }

  void _onCameraControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          final provider = Provider.of<AiCallProvider>(context, listen: false);
          provider.setListening(false);
        }
      },
      onError: (error) {
        final provider = Provider.of<AiCallProvider>(context, listen: false);
        provider.setListening(false);
      },
    );
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _startListening() async {
    final provider = Provider.of<AiCallProvider>(context, listen: false);

    // Stop TTS immediately when user starts speaking
    await _tts.stop();
    print('🔇 [TTS] Stopped TTS for user speech');

    if (!provider.isListening) {
      bool available = await _speech.initialize();
      if (available) {
        provider.setListening(true);
        setState(() {
          _transcript = '';
        });

        await _speech.listen(
          onResult: (result) {
            setState(() {
              _transcript = result.recognizedWords;
            });
            if (result.finalResult) {
              _processVoiceCommand(result.recognizedWords);
            }
          },
        );
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() {
    _speech.stop();
    final provider = Provider.of<AiCallProvider>(context, listen: false);
    provider.setListening(false);
  }

  Future<void> _processVoiceCommand(String command) async {
    final provider = Provider.of<AiCallProvider>(context, listen: false);
    await provider.processUserUtterance(command);

    // Speak the response
    if (provider.alfredoResponse.isNotEmpty) {
      await _tts.speak(provider.alfredoResponse);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Call'),
        elevation: 0,
        backgroundColor: Colors.black,
        actions: [
          Consumer<AiCallProvider>(
            builder: (context, provider, _) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      provider.isStreaming
                          ? AppTheme.successGreen
                          : AppTheme.gray600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider.isStreaming ? 'Streaming' : 'Idle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AiCallProvider>(
        builder: (context, provider, _) {
          // Setup camera listener if not already done
          if (!_cameraListenerAdded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _setupCameraListener(provider);
              }
            });
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full screen camera preview - Positioned.fill ensures bounded constraints
              Positioned.fill(child: _buildFullScreenCamera(provider)),

              // Overlay content
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(),
                    // Bottom overlay with controls and info
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status info
                          if (provider.state.recipe != null ||
                              provider.state.timers.isNotEmpty ||
                              provider.alfredoResponse.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (provider.state.recipe != null)
                                    _buildRecipeInfo(provider.state),
                                  if (provider.state.timers.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildTimers(provider.state.timers),
                                  ],
                                  if (provider.alfredoResponse.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildResponse(
                                      provider.alfredoResponse,
                                      provider.isProcessing,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          // Transcript
                          if (_transcript.isNotEmpty) _buildTranscript(),

                          // Status Notes
                          if (provider.state.notes.isNotEmpty)
                            _buildStatusNotes(provider.state.notes),

                          // Voice interface
                          _buildVoiceInterface(provider),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFullScreenCamera(AiCallProvider provider) {
    final controller = provider.cameraService.controller;

    // Check if camera is initialized
    if (!provider.cameraService.isInitialized || controller == null) {
      return Container(
        color: Colors.black,
        child: Center(child: _buildCameraPlaceholder()),
      );
    }

    // Use ValueListenableBuilder to react to controller state changes
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        // Show placeholder while initializing or if error
        if (!value.isInitialized || value.hasError) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (value.hasError)
                    Text(
                      'Camera Error: ${value.errorDescription}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    )
                  else
                    _buildCameraPlaceholder(),
                ],
              ),
            ),
          );
        }

        // Show full screen camera preview when initialized
        // CameraPreview will fill the available space from Positioned.fill
        return CameraPreview(controller);
      },
    );
  }

  Widget _buildCameraPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Camera not available',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeInfo(AiCallState state) {
    if (state.recipe == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.recipe!.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Servings: ${state.recipe!.servings}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        if (state.totalSteps > 0)
          Text(
            'Step ${state.stepIndex + 1} of ${state.totalSteps}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildTimers(List<TimerInfo> timers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.timer_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Active Timers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...timers.map((timer) => _buildTimerItem(timer)),
      ],
    );
  }

  Widget _buildTimerItem(TimerInfo timer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              timer.label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          Text(
            _formatTimer(timer.seconds),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildVoiceInterface(AiCallProvider provider) {
    return Column(
      children: [
        VoiceButton(
          isListening: provider.isListening,
          onTap: _startListening,
          size: 100,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            provider.isListening
                ? 'Listening...'
                : provider.isProcessing
                ? 'Processing...'
                : 'Tap to talk to Alfredo',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranscript() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.mic_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _transcript,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponse(String response, bool isProcessing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_rounded,
                color: AppTheme.primaryOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Alfredo:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isProcessing)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              response,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusNotes(String notes) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notes,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    // Remove camera controller listener
    if (_cameraListenerAdded) {
      final provider = Provider.of<AiCallProvider>(context, listen: false);
      final controller = provider.cameraService.controller;
      if (controller != null) {
        controller.removeListener(_onCameraControllerChanged);
      }
      _cameraListenerAdded = false;
    }
    super.dispose();
  }
}
