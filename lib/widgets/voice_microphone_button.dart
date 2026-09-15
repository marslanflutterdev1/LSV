import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/core/services/voice_service.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';
import 'dart:developer' as developer;

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
        if (_wasListening &&
            !voiceService.isListening &&
            !_hasRetrievedFinalText) {
          _hasRetrievedFinalText = true;
          _isLocallyListening = false;
          _waveAnimationController.stop();
          _waveAnimationController.reset();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _retrieveAndUpdateText(voiceService);
            }
          });
        }

        _wasListening = voiceService.isListening;

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Tooltip(
            message: voiceService.isListening
                ? 'Stop recording'
                : 'Start recording',
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isLocallyListening) ..._buildWaveCircles(),
                IconButton(
                  onPressed: _isProcessing
                      ? null
                      : () async => _handleMicTap(voiceService),
                  icon: AnimatedBuilder(
                    animation: _micAnimationController,
                    builder: (context, child) {
                      return Icon(
                        Icons.mic,
                        color: _isLocallyListening
                            ? CustomColors.primaryColor
                            : (_isProcessing
                            ? Colors.grey.shade400
                            : Colors.grey),
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
      AnimatedBuilder(
        animation: _waveAnimationController,
        builder: (context, child) {
          final delayedValue =
          (_waveAnimationController.value - 0.3).clamp(0.0, 1.0);
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
      // ✅ Clear any stale error from a previous denied attempt.
      // This ensures a fresh check whenever the user taps the mic.
      voiceService.resetErrorState();

      if (_isLocallyListening) {
        await _stopListening(voiceService);
      } else {
        if (!voiceService.isInitialized) {
          // Silent initialization — no blocking dialog.
          await voiceService.initializeSpeechToText();

          if (!voiceService.isInitialized) {
            _showInfoMessage(
              voiceService.error ??
                  'Voice input is unavailable. You can type your search instead.',
            );
            if (mounted) setState(() => _isProcessing = false);
            return;
          }
        }

        await _startListening(voiceService);
      }
    } catch (e) {
      // Never crash, never show a dialog.
      _showInfoMessage(
        'Voice input is unavailable. You can type your search instead.',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _startListening(VoiceService voiceService) async {
    if (voiceService.error != null) {
      _showInfoMessage(voiceService.error ?? 'Voice input is unavailable.');
      return;
    }

    _hasRetrievedFinalText = false;
    setState(() => _isLocallyListening = true);

    _micAnimationController.repeat(reverse: true);
    _waveAnimationController.repeat();
    widget.onListeningStart?.call();

    await voiceService.startListening();

    if (voiceService.error != null && mounted) {
      _showInfoMessage(voiceService.error ?? 'Voice input is unavailable.');
      _micAnimationController.stop();
      _micAnimationController.reset();
      _waveAnimationController.stop();
      _waveAnimationController.reset();
      setState(() => _isLocallyListening = false);
      return;
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLocallyListening) {
        _stopListening(voiceService);
      }
    });
  }

  Future<void> _retrieveAndUpdateText(VoiceService voiceService) async {
    if (_micAnimationController.isAnimating) {
      _micAnimationController.stop();
      _micAnimationController.reset();
    }
    if (_waveAnimationController.isAnimating) {
      _waveAnimationController.stop();
      _waveAnimationController.reset();
    }

    widget.onListeningEnd?.call();

    final recognizedText = voiceService.recognizedText;

    if (recognizedText.isNotEmpty) {
      widget.controller.text = recognizedText;
      _showSuccessMessage(recognizedText);
      developer.log(
        'VoiceMicrophoneButton: Text updated to: $recognizedText',
      );
      voiceService.getTextAndReset();
    } else {
      _showInfoMessage('No speech detected. Please try again.');
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

    final recognizedText = voiceService.getTextAndReset();
    if (recognizedText.isNotEmpty) {
      widget.controller.text = recognizedText;
      _showSuccessMessage(recognizedText);
    } else {
      _showInfoMessage('No speech detected. Please try again.');
    }
  }

  void _showSuccessMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recognized Text: $text',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: CustomColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: CustomColors.primaryColor,
      ),
    );
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: CustomColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: CustomColors.black.withOpacity(0.5),
      ),
    );
  }
}