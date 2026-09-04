import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer' as developer;

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String? _error;
  List<stt.LocaleName>? _localeNames;
  String _currentLocale = 'en_US';

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Initialize speech to text - called once
  Future<bool> initializeSpeechToText() async {
    if (_isInitialized) {
      developer.log('VoiceService: Already initialized');
      return true;
    }

    try {
      developer.log('VoiceService: Initializing speech to text on ${Platform.operatingSystem}...');
      
      final available = await _speechToText.initialize(
        onError: (error) {
          developer.log('VoiceService Error: ${error.errorMsg}');
          _error = 'Error: ${error.errorMsg}';
          notifyListeners();
        },
        onStatus: (status) {
          developer.log('VoiceService Status: $status');
        },
        debugLogging: false,
        finalTimeout: const Duration(seconds: 30),
      );

      if (available) {
        _isInitialized = true;
        
        // Get available locales
        try {
          _localeNames = await _speechToText.locales();
          developer.log('VoiceService: Available locales: ${_localeNames?.length}');
          if (_localeNames != null && _localeNames!.isNotEmpty) {
            developer.log('VoiceService: First locale: ${_localeNames!.first.localeId}');
          }
        } catch (e) {
          developer.log('VoiceService: Error getting locales: $e');
        }

        developer.log('VoiceService: Initialized successfully');
      } else {
        _error = 'Speech recognition not available on this device.\nMake sure Google Play Services is installed.';
        developer.log('VoiceService: Not available on device');
      }

      return available;
    } catch (e) {
      _error = 'Failed to initialize: $e';
      developer.log('VoiceService Error: $e');
      return false;
    }
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      developer.log('VoiceService: Microphone permission: ${status.name}');

      if (status.isDenied) {
        _error = 'Microphone permission denied';
        notifyListeners();
        return false;
      } else if (status.isPermanentlyDenied) {
        _error = 'Microphone permission permanently denied.\nPlease enable it in app settings.';
        notifyListeners();
        openAppSettings();
        return false;
      }

      return status.isGranted;
    } catch (e) {
      _error = 'Error requesting permission: $e';
      developer.log('VoiceService Permission Error: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening() async {
    if (_isListening) {
      developer.log('VoiceService: Already listening');
      return;
    }

    try {
      developer.log('VoiceService: Start listening requested');

      // Request permission
      final permissionGranted = await requestMicrophonePermission();
      if (!permissionGranted) {
        _isListening = false;
        notifyListeners();
        return;
      }

      // Initialize if needed
      if (!_isInitialized) {
        final initialized = await initializeSpeechToText();
        if (!initialized) {
          _isListening = false;
          notifyListeners();
          return;
        }
      }

      // Check if speech recognition is available
      if (!_speechToText.isAvailable) {
        _error = 'Speech recognition is not available at this moment.\nPlease try again.';
        _isListening = false;
        notifyListeners();
        developer.log('VoiceService: Not available');
        return;
      }

      _error = null;
      _recognizedText = '';
      _isListening = true;
      notifyListeners();

      developer.log('VoiceService: Starting to listen with locale $_currentLocale...');

      // Build the listen call
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          developer.log('VoiceService: Recognized (isFinal: ${result.finalResult}): $_recognizedText');
          notifyListeners();
          
          // Auto-stop if final result
          if (result.finalResult) {
            developer.log('VoiceService: Final result received, stopping');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_isListening) {
                stopListening();
              }
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: (level) {
          // Silently track sound level
        },
        cancelOnError: false,
        localeId: _currentLocale,
      );

      developer.log('VoiceService: Listening started successfully');
    } catch (e) {
      _error = 'Error during listening: $e';
      _isListening = false;
      developer.log('VoiceService Error: $e');
      notifyListeners();
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (!_isListening) {
      developer.log('VoiceService: Not currently listening');
      return;
    }

    try {
      developer.log('VoiceService: Stopping listener...');
      await Future.delayed(const Duration(milliseconds: 100));

      await _speechToText.stop();

      _isListening = false;
      developer.log('VoiceService: Listener stopped. Recognized: $_recognizedText');
      notifyListeners();
    } catch (e) {
      _error = 'Error stopping listener: $e';
      _isListening = false;
      developer.log('VoiceService Error stopping: $e');
      notifyListeners();
    }
  }

  /// Cancel listening and clear text
  Future<void> cancelListening() async {
    try {
      developer.log('VoiceService: Canceling...');
      await _speechToText.cancel();
      _isListening = false;
      _recognizedText = '';
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error canceling listener: $e';
      developer.log('VoiceService Error canceling: $e');
      notifyListeners();
    }
  }

  /// Get recognized text and reset
  String getTextAndReset() {
    final text = _recognizedText;
    developer.log('VoiceService: Getting text and resetting: $text');
    _recognizedText = '';
    _isListening = false;
    _error = null;
    notifyListeners();
    return text;
  }

  @override
  void dispose() {
    developer.log('VoiceService: Disposing');
    _speechToText.cancel();
    super.dispose();
  }
}
