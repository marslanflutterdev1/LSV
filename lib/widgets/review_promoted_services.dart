
import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewPromptService with WidgetsBindingObserver {
  ReviewPromptService._();

  static final ReviewPromptService instance =
  ReviewPromptService._();

  static const _lastAttemptKey = 'review_last_attempt_ms';
  static const _attemptCountKey = 'review_attempt_count';

  static const Duration _minDelay = Duration(minutes: 2);
  static const Duration _maxDelay = Duration(minutes: 3);
  static const Duration _cooldown = Duration(days: 30);
  static const int _maxAttempts = 3;

  final InAppReview _review = InAppReview.instance;
  final Random _random = Random.secure();

  SharedPreferences? _prefs;
  Timer? _timer;
  Stopwatch? _stopwatch;

  Duration _activeElapsed = Duration.zero;
  Duration _sessionThreshold = Duration.zero;

  bool _initialized = false;
  bool _requestInProgress = false;
  bool _handledThisSession = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    WidgetsBinding.instance.addObserver(this);

    _initialized = true;
    _chooseThreshold();

    if (WidgetsBinding.instance.lifecycleState ==
        AppLifecycleState.resumed) {
      _startTracking();
    }
  }

  void _chooseThreshold() {
    final minMs = _minDelay.inMilliseconds;
    final maxMs = _maxDelay.inMilliseconds;

    _sessionThreshold = Duration(
      milliseconds: minMs + _random.nextInt(maxMs - minMs + 1),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTracking();
    } else {
      _stopTracking();
    }
  }

  void _startTracking() {
    if (!_initialized ||
        _handledThisSession ||
        _requestInProgress ||
        _timer != null) {
      return;
    }

    _stopwatch = Stopwatch()..start();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _checkEligibility(),
    );
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;

    final stopwatch = _stopwatch;
    if (stopwatch != null) {
      if (stopwatch.isRunning) {
        _activeElapsed += stopwatch.elapsed;
      }
      stopwatch.stop();
      _stopwatch = null;
    }
  }

  Future<void> _checkEligibility() async {
    if (_requestInProgress ||
        _handledThisSession ||
        _stopwatch == null ||
        !_stopwatch!.isRunning) {
      return;
    }

    final activeTime = _activeElapsed + _stopwatch!.elapsed;

    if (activeTime < _sessionThreshold) return;

    final prefs = _prefs;
    if (prefs == null) return;

    final attempts = prefs.getInt(_attemptCountKey) ?? 0;

    if (attempts >= _maxAttempts) {
      _handledThisSession = true;
      _stopTracking();
      return;
    }

    final lastAttemptMs = prefs.getInt(_lastAttemptKey) ?? 0;

    if (lastAttemptMs > 0) {
      final lastAttempt =
      DateTime.fromMillisecondsSinceEpoch(lastAttemptMs);

      if (DateTime.now().difference(lastAttempt) < _cooldown) {
        _handledThisSession = true;
        _stopTracking();
        return;
      }
    }

    _requestInProgress = true;
    _handledThisSession = true;
    _stopTracking();

    try {
      // Persist the attempt before requesting the native prompt.
      await prefs.setInt(
        _lastAttemptKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      await prefs.setInt(_attemptCountKey, attempts + 1);

      if (await _review.isAvailable()) {
        await _review.requestReview();
      }
    } catch (error, stackTrace) {
      debugPrint('Review request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _requestInProgress = false;
    }
  }

  /// Call only from a debug/testing control.
  Future<void> resetForTesting() async {
    final prefs = _prefs;
    if (prefs == null) return;

    _stopTracking();

    await prefs.remove(_lastAttemptKey);
    await prefs.remove(_attemptCountKey);

    _activeElapsed = Duration.zero;
    _handledThisSession = false;
    _chooseThreshold();

    if (WidgetsBinding.instance.lifecycleState ==
        AppLifecycleState.resumed) {
      _startTracking();
    }
  }

  void dispose() {
    _stopTracking();
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }
}
