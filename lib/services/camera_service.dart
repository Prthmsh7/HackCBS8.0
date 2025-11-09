import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isStreaming = false;
  Timer? _frameTimer;
  Function(String imagePath)? _onFrameCaptured;

  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;
  CameraController? get controller => _controller;

  Future<bool> initialize() async {
    if (_isInitialized) {
      print('✅ [CAMERA] Already initialized');
      return true;
    }

    // Request camera permission
    print('📷 [CAMERA] Requesting camera permission...');
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      print('❌ [CAMERA] Camera permission denied');
      return false;
    }

    try {
      print('📷 [CAMERA] Getting available cameras...');
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('❌ [CAMERA] No cameras available');
        return false;
      }

      print('📷 [CAMERA] Creating camera controller...');
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high, // Changed from medium to high for better quality
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      print('📷 [CAMERA] Initializing camera controller...');
      await _controller!.initialize();
      
      // Verify controller is actually initialized
      if (_controller != null && _controller!.value.isInitialized) {
        _isInitialized = true;
        print('✅ [CAMERA] Camera initialized successfully');
        
        // Set focus mode to auto for better image quality
        try {
          await _controller!.setFocusMode(FocusMode.auto);
          await _controller!.setExposureMode(ExposureMode.auto);
          print('✅ [CAMERA] Focus and exposure modes set');
        } catch (e) {
          // Focus modes might not be supported on all devices
          print('⚠️ [CAMERA] Could not set focus mode: $e');
        }
        return true;
      } else {
        print('❌ [CAMERA] Controller not properly initialized');
        _isInitialized = false;
        await _controller?.dispose();
        _controller = null;
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [CAMERA] Error initializing camera: $e');
      print('❌ [CAMERA] Stack trace: $stackTrace');
      _isInitialized = false;
      await _controller?.dispose();
      _controller = null;
      return false;
    }
  }

  void startFrameStream(int intervalSeconds, Function(String imagePath) onFrame) {
    if (!_isInitialized || _controller == null) return;
    if (_isStreaming) stopFrameStream();

    _onFrameCaptured = onFrame;
    _isStreaming = true;

    _frameTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _captureFrame(),
    );

    // Capture initial frame
    _captureFrame();
  }

  void stopFrameStream() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _isStreaming = false;
    _onFrameCaptured = null;
  }

  Future<String?> captureFrame() async {
    if (!_isInitialized || _controller == null) return null;
    if (!_controller!.value.isInitialized) return null;

    try {
      // Try to lock focus before capturing for better image quality
      try {
        await _controller!.setFocusMode(FocusMode.locked);
        // Wait a bit for focus to lock
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        // Focus lock might fail or not be supported, continue anyway
        print('⚠️ [CAMERA] Focus lock not supported or failed: $e');
      }
      
      final image = await _controller!.takePicture();
      print('📸 [CAMERA] Frame captured: ${image.path}');
      return image.path;
    } catch (e, stackTrace) {
      print('❌ [CAMERA] Error capturing frame: $e');
      print('❌ [CAMERA] Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _captureFrame() async {
    if (!_isStreaming) return;
    final path = await captureFrame();
    if (path != null && _onFrameCaptured != null) {
      _onFrameCaptured!(path);
    }
  }

  Future<void> dispose() async {
    stopFrameStream();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}


