import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/core/services/voice_service.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/widgets/custom_button.dart';
import 'dart:developer' as developer;

import 'package:satellite_view/widgets/custom_dialog_box.dart';

class VoiceMicrophoneButton extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onListeningStart;
  final VoidCallback? onListeningEnd;

  const VoiceMicrophoneButton({
    super.key,
    required this.controller,
    this.onListeningStart,
    this.onListeningEnd,
  });

  @override
  State<VoiceMicrophoneButton> createState() => _VoiceMicrophoneButtonState();
}

class _VoiceMicrophoneButtonState extends State<VoiceMicrophoneButton>
    with TickerProviderStateMixin {
  late AnimationController _micAnimationController;
  late AnimationController _waveAnimationController;
  bool _isProcessing = false;
  bool _wasListening = false;
  bool _hasRetrievedFinalText = false;
  bool _isLocallyListening = false;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceService>(
      builder: (context, voiceService, _) {
        // Handle when listening stops (automatically or manually)
        if (_wasListening && !voiceService.isListening && !_hasRetrievedFinalText) {
          _hasRetrievedFinalText = true;
          _isLocallyListening = false;
          _waveAnimationController.stop();
          _waveAnimationController.reset();
          
          // Retrieve text in next frame to ensure state is updated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _retrieveAndUpdateText(voiceService);
            }
          });
        }

        // Track listening state for next build
        _wasListening = voiceService.isListening;

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Tooltip(
            message: voiceService.isListening ? 'Stop recording' : 'Start recording',
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wave animation - only show when locally listening
                if (_isLocallyListening)
                  ..._buildWaveCircles(),
                
                // Microphone button
                IconButton(
                  onPressed: _isProcessing ? null : () async => _handleMicTap(voiceService),
                  icon: AnimatedBuilder(
                    animation: _micAnimationController,
                    builder: (context, child) {
                      return Icon(
                        Icons.mic,
                        color: _isLocallyListening
                            ? CustomColors.primaryColor
                            : (_isProcessing ? Colors.grey.shade400 : Colors.grey),
                        size: _isLocallyListening
                            ? 24 + (_micAnimationController.value * 2)
                            : 24,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildWaveCircles() {
    return [
      // Wave 1 - largest
      AnimatedBuilder(
        animation: _waveAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + (_waveAnimationController.value * 1.5),
            child: Opacity(
              opacity: (1 - _waveAnimationController.value).clamp(0.0, 1.0),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CustomColors.primaryColor.withOpacity(0.5),
                    width: 5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      
      // Wave 2 - medium
      AnimatedBuilder(
        animation: _waveAnimationController,
        builder: (context, child) {
          final delayedValue = (_waveAnimationController.value - 0.3).clamp(0.0, 1.0);
          return Transform.scale(
            scale: 1 + (delayedValue * 1.2),
            child: Opacity(
              opacity: (1 - delayedValue).clamp(0.0, 1.0),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CustomColors.primaryColor.withOpacity(0.4),
                    width: 5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Future<void> _handleMicTap(VoiceService voiceService) async {
    setState(() => _isProcessing = true);
    
    try {
      if (_isLocallyListening) {
        await _stopListening(voiceService);
      } else {
        // First use check
        if (!voiceService.isInitialized) {
          _showInfoDialog(
            'Initializing Voice Recognition',
            'Please wait while speech recognition is being set up for the first time.',
          );
          await voiceService.initializeSpeechToText();
          
          if (!voiceService.isInitialized) {
            _showErrorDialog(
              voiceService.error ?? 
              'Voice recognition not available. Ensure Google Play Services is installed on your device.'
            );
            if (mounted) {
              setState(() => _isProcessing = false);
            }
            return;
          }
        }
        
        await _startListening(voiceService);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _startListening(VoiceService voiceService) async {
    if (voiceService.error != null) {
      _showErrorDialog(voiceService.error ?? 'Unknown error');
      return;
    }

    // Reset the flag for this new listening session
    _hasRetrievedFinalText = false;

    // Set local listening state
    setState(() => _isLocallyListening = true);

    _micAnimationController.repeat(reverse: true);
    _waveAnimationController.repeat();
    widget.onListeningStart?.call();
    
    await voiceService.startListening();

    if (voiceService.error != null && mounted) {
      _showErrorDialog(voiceService.error ?? 'Failed to start listening');
      _micAnimationController.stop();
      _micAnimationController.reset();
      _waveAnimationController.stop();
      _waveAnimationController.reset();
      setState(() => _isLocallyListening = false);
      return;
    }

    // Auto stop after 20 seconds (fallback if final result doesn't trigger auto-stop)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLocallyListening) {
        _stopListening(voiceService);
      }
    });
  }

  Future<void> _retrieveAndUpdateText(VoiceService voiceService) async {
    // Stop the animation
    if (_micAnimationController.isAnimating) {
      _micAnimationController.stop();
      _micAnimationController.reset();
    }
    
    if (_waveAnimationController.isAnimating) {
      _waveAnimationController.stop();
      _waveAnimationController.reset();
    }
    
    widget.onListeningEnd?.call();

    // Get the recognized text
    final recognizedText = voiceService.recognizedText;
    
    if (recognizedText.isNotEmpty) {
      // Update the text field
      widget.controller.text = recognizedText;
      _showSuccessMessage(recognizedText);
      developer.log('VoiceMicrophoneButton: Text updated to: $recognizedText');
      
      // Clear the text from service
      voiceService.getTextAndReset();
    } else {
      _showInfoMessage('No speech detected. Please try again.');
      developer.log('VoiceMicrophoneButton: No recognized text');
    }
  }

  Future<void> _stopListening(VoiceService voiceService) async {
    await _stopListeningInternal(voiceService);
  }

  Future<void> _stopListeningInternal(VoiceService voiceService) async {
    _micAnimationController.stop();
    _micAnimationController.reset();
    _waveAnimationController.stop();
    _waveAnimationController.reset();
    widget.onListeningEnd?.call();
    
    setState(() => _isLocallyListening = false);
    
    await voiceService.stopListening();

    if (!mounted) return;

    // Update the text field with recognized text
    final recognizedText = voiceService.getTextAndReset();
    if (recognizedText.isNotEmpty) {
      widget.controller.text = recognizedText;
      _showSuccessMessage(recognizedText);
    } else {
      _showInfoMessage('No speech detected. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        icon: Center(
          child: Text('Voice Input Error',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              color: CustomColors.primaryColor,
              fontWeight: FontWeight.bold,

            ),),
        ),
        title:Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(message),
        ),
        titleTextStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(
        ),
        content: SizedBox.shrink(),
        actions: [
          CustomButton(
            text: 'Ok',
            isLoading: false,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        icon: Center(
          child: Text(title,
            style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            color: CustomColors.primaryColor,
            fontWeight: FontWeight.bold,

          ),),
        ),
        title:Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(message),
        ),
        titleTextStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(
        ),
        content: SizedBox.shrink(),
        actions: [
          CustomButton(
            text: 'Ok',
            isLoading: false,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recognized Text: $text', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: CustomColors.white, fontWeight: FontWeight.bold),),
        duration: const Duration(seconds: 2),
        backgroundColor: CustomColors.primaryColor,
      ),
    );
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: CustomColors.white, fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 2),
        backgroundColor: CustomColors.grey,
      ),
    );
  }
}
