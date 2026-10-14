
import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewPromptService with WidgetsBindingObserver {
  ReviewPromptService._();

  static final ReviewPromptService instance =
  ReviewPromptService._();

  final InAppReview _review = InAppReview.instance;
  final Random _random = Random();

  static const String _lastRequestKey =
      'review_prompt_last_request_ms';

  static const String _appStoreId = '6756287339';

  static const Duration _cooldown = Duration(days: 90);

  Timer? _timer;
  DateTime? _foregroundStartedAt;

  Duration _activeTime = Duration.zero;
  late Duration _targetTime;

  bool _initialized = false;
  bool _isForeground = false;
  bool _requestedThisSession = false;
  bool _requestInProgress = false;

  /// Initialize once, after Flutter bindings are ready.
  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    _targetTime = Duration(
      seconds: 180 + _random.nextInt(61),
    );

    WidgetsBinding.instance.addObserver(this);

    _isForeground =
        WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed;

    // Before runApp(), lifecycleState can be null.
    // Start counting once the app actually resumes.
    if (_isForeground) {
      _startForegroundTimer();
    }
  }

  void _startForegroundTimer() {
    if (!_initialized ||
        !_isForeground ||
        _requestedThisSession ||
        _requestInProgress) {
      return;
    }

    _foregroundStartedAt ??= DateTime.now();

    _timer?.cancel();

    final remaining = _targetTime - _activeTime;

    if (remaining <= Duration.zero) {
      unawaited(_tryRequestReview());
      return;
    }

    _timer = Timer(remaining, () {
      _updateActiveTime();
      unawaited(_tryRequestReview());
    });
  }

  void _updateActiveTime() {
    final startedAt = _foregroundStartedAt;

    if (startedAt == null) return;

    _activeTime += DateTime.now().difference(startedAt);
    _foregroundStartedAt = null;
  }

  Future<void> _tryRequestReview() async {
    if (!_initialized ||
        !_isForeground ||
        _requestedThisSession ||
        _requestInProgress) {
      return;
    }

    _requestInProgress = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (!_isForeground) return;

      // Respect our own 90-day cooldown.
      final lastRequest = prefs.getInt(_lastRequestKey);

      if (lastRequest != null) {
        final elapsedMs =
            DateTime.now().millisecondsSinceEpoch - lastRequest;

        final cooldownMs = _cooldown.inMilliseconds;

        if (elapsedMs >= 0 && elapsedMs < cooldownMs) {
          _requestedThisSession = true;
          debugPrint('Review skipped: 90-day cooldown.');
          return;
        }
      }

      if (!_isForeground) return;

      final available = await _review.isAvailable();

      if (!available || !_isForeground) {
        debugPrint('Native review request unavailable.');
        _requestedThisSession = true;
        return;
      }

      // Save the attempt before calling the native review API.
      // This prevents repeated requests after restarting the app.
      _requestedThisSession = true;

      await prefs.setInt(
        _lastRequestKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      if (!_isForeground) return;

      debugPrint('Requesting native in-app review.');

      await _review.requestReview();

      debugPrint('Native review request completed.');
    } catch (error, stackTrace) {
      debugPrint('In-app review error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _requestInProgress = false;

      // Handle the app returning to the foreground while an
      // asynchronous review check was running.
      if (_isForeground && !_requestedThisSession) {
        _startForegroundTimer();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;

    if (resumed == _isForeground) return;

    if (!resumed) {
      // Pause the active-time clock.
      _timer?.cancel();
      _timer = null;
      _updateActiveTime();
      _isForeground = false;
      return;
    }

    _isForeground = true;
    _startForegroundTimer();
  }

  /// Use only for an explicit Rate App button.
  ///
  /// Android opens the Google Play listing for this app.
  /// iOS uses the configured Apple App Store ID.
  Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing(
        appStoreId: _appStoreId,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not open store listing: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Optional cleanup when the service is no longer required.
  void dispose() {
    _timer?.cancel();
    _timer = null;

    if (_isForeground) {
      _updateActiveTime();
    }

    WidgetsBinding.instance.removeObserver(this);

    _isForeground = false;
    _initialized = false;
  }
}
