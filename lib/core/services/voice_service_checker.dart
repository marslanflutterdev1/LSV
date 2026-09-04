import 'package:satellite_view/core/services/voice_service.dart';
import 'dart:developer' as developer;

class VoiceServiceChecker {
  static Future<Map<String, dynamic>> checkVoiceServiceStatus(VoiceService voiceService) async {
    final status = <String, dynamic>{
      'initialized': false,
      'available': false,
      'error': null,
      'details': <String, String>{},
    };

    try {
      developer.log('VoiceServiceChecker: Starting checks...');
      
      // Try to initialize
      final initialized = await voiceService.initializeSpeechToText();
      status['initialized'] = initialized;
      developer.log('VoiceServiceChecker: Initialized = $initialized');

      if (!initialized) {
        status['error'] = 'Failed to initialize speech recognition';
        status['details']['error'] = voiceService.error ?? 'Unknown error';
        return status;
      }

      // Check if available
      status['available'] = true;
      status['details']['status'] = 'Voice service is available and ready to use';

      return status;
    } catch (e) {
      developer.log('VoiceServiceChecker Error: $e');
      status['error'] = 'Error checking status: $e';
      status['details']['error'] = e.toString();
      return status;
    }
  }

  static String getStatusMessage(Map<String, dynamic> status) {
    if (status['available'] == true) {
      return 'Voice service ready ✓';
    }
    
    if (status['initialized'] == false) {
      return 'Voice service not available. Make sure you have Google Play Services installed.';
    }

    final error = status['details']['error'] as String?;
    return 'Voice Error: $error';
  }
}
